require('dotenv').config();

const multer = require('multer');
const FormData = require('form-data');

const upload = multer();
const express = require('express');
const axios = require('axios');
const crypto = require('crypto');

const CONTROL_ID_GROUP_ADULT = 1;
const CONTROL_ID_GROUP_MINOR = 1;

function hashPassword(password) {
  return crypto.createHash('sha256').update(password).digest('hex');
}

function checkPassword(password, hash) {
  return hashPassword(password) === hash;
}

function cleanCpf(cpf) {
  return String(cpf || '').replace(/\D/g, '');
}

function isValidCpf(cpf) {
  cpf = cleanCpf(cpf);

  if (cpf.length !== 11) return false;
  if (/^(\d)\1{10}$/.test(cpf)) return false;

  let sum = 0;
  let rest;

  for (let i = 1; i <= 9; i++) {
    sum += parseInt(cpf.substring(i - 1, i), 10) * (11 - i);
  }

  rest = (sum * 10) % 11;
  if (rest === 10 || rest === 11) rest = 0;
  if (rest !== parseInt(cpf.substring(9, 10), 10)) return false;

  sum = 0;

  for (let i = 1; i <= 10; i++) {
    sum += parseInt(cpf.substring(i - 1, i), 10) * (12 - i);
  }

  rest = (sum * 10) % 11;
  if (rest === 10 || rest === 11) rest = 0;

  return rest === parseInt(cpf.substring(10, 11), 10);
}

function normalizeBirthDate(value) {
  if (!value) return null;

  const text = String(value).trim();

  let year;
  let month;
  let day;

  // Aceita YYYY-MM-DD
  if (/^\d{4}-\d{2}-\d{2}$/.test(text)) {
    [year, month, day] = text.split('-').map(Number);
  }

  // Aceita DD/MM/YYYY
  else if (/^\d{2}\/\d{2}\/\d{4}$/.test(text)) {
    const parts = text.split('/');
    day = Number(parts[0]);
    month = Number(parts[1]);
    year = Number(parts[2]);
  }

  else {
    return null;
  }

  const date = new Date(Date.UTC(year, month - 1, day));

  const valid =
    date.getUTCFullYear() === year &&
    date.getUTCMonth() === month - 1 &&
    date.getUTCDate() === day;

  if (!valid) {
    return null;
  }

  return `${String(year).padStart(4, '0')}-${String(month).padStart(2, '0')}-${String(day).padStart(2, '0')}`;
}

function canManageUser(req, userId) {
  return req.user.id === userId || req.user.role === 'admin';
}

function isUnder18(birthDate) {
  if (!birthDate) {
    return false;
  }

  const date = new Date(birthDate);

  if (Number.isNaN(date.getTime())) {
    return false;
  }

  const today = new Date();

  let age = today.getFullYear() - date.getFullYear();

  const hasHadBirthdayThisYear =
    today.getMonth() > date.getMonth() ||
    (today.getMonth() === date.getMonth() && today.getDate() >= date.getDate());

  if (!hasHadBirthdayThisYear) {
    age -= 1;
  }

  return age < 18;
}

const jwt = require('jsonwebtoken');
const helmet = require('helmet');
const cors = require('cors');
const { Pool } = require('pg');

const app = express();

app.use(helmet());
app.use(cors());
app.use(express.json({ limit: '15mb' }));

const pool = new Pool({
  connectionString: process.env.DATABASE_URL
});

function formatMarketingBanner(row) {
  return {
    id: Number(row.id),
    title: row.title || null,
    image_url: `/marketing/banners/${row.id}/image`,
    active: row.active === true,
    sort_order: Number(row.sort_order || 0),
    starts_at: row.starts_at || null,
    ends_at: row.ends_at || null,
    created_at: row.created_at || null,
    updated_at: row.updated_at || null
  };
}

async function deactivateExpiredMarketingBanners() {
  await pool.query(`
    UPDATE marketing_banners
    SET active = FALSE, updated_at = NOW()
    WHERE active = TRUE
      AND ends_at IS NOT NULL
      AND ends_at <= NOW()
  `);
}

const marketingScheduleTimer = setInterval(() => {
  deactivateExpiredMarketingBanners().catch(error => {
    console.error('Erro ao encerrar campanhas programadas:', error);
  });
}, 60 * 1000);

marketingScheduleTimer.unref();

function detectMarketingImageMimeType(buffer) {
  if (!Buffer.isBuffer(buffer) || buffer.length < 12) {
    return null;
  }

  const isJpeg =
    buffer[0] === 0xff && buffer[1] === 0xd8 && buffer[2] === 0xff;
  const isPng =
    buffer[0] === 0x89 &&
    buffer[1] === 0x50 &&
    buffer[2] === 0x4e &&
    buffer[3] === 0x47;
  const isWebp =
    buffer.subarray(0, 4).toString('ascii') === 'RIFF' &&
    buffer.subarray(8, 12).toString('ascii') === 'WEBP';

  if (isJpeg) return 'image/jpeg';
  if (isPng) return 'image/png';
  if (isWebp) return 'image/webp';

  return null;
}

function normalizeOptionalText(value) {
  if (value == null) {
    return null;
  }

  const clean = String(value).trim();

  return clean === '' ? null : clean;
}

function normalizeIp(ip) {
  if (!ip) return null;

  let normalizedIp = String(ip).trim();

  if (normalizedIp.includes(',')) {
    normalizedIp = normalizedIp.split(',')[0].trim();
  }

  if (normalizedIp.startsWith('::ffff:')) {
    normalizedIp = normalizedIp.substring(7);
  }

  return normalizedIp || null;
}

function getRequestAuditData(req) {
  const forwardedHeader = req.headers['x-forwarded-for'];

  const forwardedIp = normalizeIp(
    Array.isArray(forwardedHeader)
      ? forwardedHeader[0]
      : forwardedHeader
  );

  const directIp = normalizeIp(
    req.ip ||
    req.socket?.remoteAddress ||
    null
  );

  return {
    directIp,
    forwardedIp,
    userAgent: req.headers['user-agent']?.toString() || null,
    deviceId: req.headers['x-device-id']?.toString() || null,
    appVersion: req.headers['x-app-version']?.toString() || null,
    platform: req.headers['x-platform']?.toString() || null,
  };
}

async function createAuditEvent({
  actorUserId = null,
  subjectUserId = null,
  actorType = 'user',
  action,
  entityType = null,
  entityId = null,
  result = 'success',
  req = null,
  requestId = null,
  metadata = {},
}) {
  if (!action || typeof action !== 'string') {
    throw new Error('Ação de auditoria é obrigatória');
  }

  const requestData = req
    ? getRequestAuditData(req)
    : {
      directIp: null,
      forwardedIp: null,
      userAgent: null,
      deviceId: null,
      appVersion: null,
      platform: null,
    };

  const safeMetadata =
    metadata &&
      typeof metadata === 'object' &&
      !Array.isArray(metadata)
      ? metadata
      : {};

  const resultQuery = await pool.query(
    `
      INSERT INTO audit_events (
        actor_user_id,
        subject_user_id,
        actor_type,
        action,
        entity_type,
        entity_id,
        result,
        ip_address,
        forwarded_ip,
        user_agent,
        device_id,
        app_version,
        platform,
        request_id,
        metadata
      )
      VALUES (
        $1, $2, $3, $4, $5,
        $6, $7, $8, $9, $10,
        $11, $12, $13, $14, $15::jsonb
      )
      RETURNING id
    `,
    [
      actorUserId,
      subjectUserId,
      actorType,
      action,
      entityType,
      entityId !== null ? String(entityId) : null,
      result,
      requestData.directIp,
      requestData.forwardedIp,
      requestData.userAgent,
      requestData.deviceId,
      requestData.appVersion,
      requestData.platform,
      requestId,
      JSON.stringify(safeMetadata),
    ]
  );

  return resultQuery.rows[0];
}

async function addFacialUserToAccessGroup(controlIdUserId, birthDate) {
  const facialUserId = Number(controlIdUserId);

  if (!Number.isInteger(facialUserId) || facialUserId <= 0) {
    throw new Error(`ID facial inválido para vínculo com grupo: ${controlIdUserId}`);
  }

  const session = await getFacialSession();

  const under18 = isUnder18(birthDate);

  const groupId = under18
    ? CONTROL_ID_GROUP_MINOR
    : CONTROL_ID_GROUP_ADULT;

  const response = await axios.post(
    `${process.env.FACIAL_BASE_URL}/create_objects.fcgi?session=${encodeURIComponent(session)}`,
    {
      object: 'user_groups',
      fields: ['user_id', 'group_id'],
      values: [
        {
          user_id: facialUserId,
          group_id: groupId
        }
      ]
    },
    {
      timeout: 30000
    }
  );

  return {
    groupId,
    response: response.data
  };
}

function maskPhone(phone) {
  if (!phone) return null;

  const digits = String(phone).replace(/\D/g, '');

  if (digits.length < 4) {
    return '****';
  }

  return `${'*'.repeat(Math.max(digits.length - 4, 4))}${digits.slice(-4)}`;
}

async function safeCreateAuditEvent(data) {
  try {
    return await createAuditEvent(data);
  } catch (auditError) {
    console.error(
      'Erro ao registrar evento de auditoria:',
      auditError
    );

    return null;
  }
}


let facialSession = null;

async function loginFacial() {
  const response = await axios.post(`${process.env.FACIAL_BASE_URL}/login.fcgi`, {
    login: process.env.FACIAL_USER,
    password: process.env.FACIAL_PASSWORD
  });

  facialSession = response.data.session;
  return facialSession;
}

async function getFacialSession() {
  if (!facialSession) {
    return await loginFacial();
  }

  return facialSession;
}

async function createFacialUser({ name, cpf }) {
  const session = await getFacialSession();

  const cleanCpf = String(cpf || '').replace(/\D/g, '');

  const response = await axios.post(
    `${process.env.FACIAL_BASE_URL}/create_objects.fcgi?session=${session}`,
    {
      object: 'users',
      values: [
        {
          name: String(name).trim(),
          registration: cleanCpf
        }
      ]
    }
  );

  const createdUserId =
    response.data?.ids?.[0] ||
    response.data?.id ||
    response.data?.user_id ||
    null;

  if (!createdUserId) {
    throw new Error('Facial não retornou o ID do usuário criado.');
  }

  return {
    controlIdUserId: createdUserId,
    data: response.data
  };
}

async function authMiddleware(req, res, next) {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({
      code: 'TOKEN_MISSING',
      message: 'Token ausente'
    });
  }

  const [, token] = authHeader.split(' ');

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    if (!decoded.id || !decoded.session_version) {
      return res.status(401).json({
        code: 'TOKEN_INVALID',
        message: 'Token inválido'
      });
    }

    const result = await pool.query(
      `
      SELECT
        id,
        role,
        active,
        session_version
      FROM app_users
      WHERE id = $1
      LIMIT 1
      `,
      [decoded.id]
    );

    if (result.rowCount === 0) {
      return res.status(401).json({
        code: 'USER_NOT_FOUND',
        message: 'Usuário não encontrado'
      });
    }

    const user = result.rows[0];

    if (!user.active) {
      return res.status(403).json({
        code: 'USER_INACTIVE',
        message: 'Usuário inativo'
      });
    }

    if (Number(decoded.session_version) !== Number(user.session_version)) {
      return res.status(401).json({
        code: 'SESSION_EXPIRED',
        message: 'Sessão expirada. Faça login novamente.'
      });
    }

    req.user = {
      id: user.id,
      role: user.role,
      active: user.active,
      session_version: user.session_version
    };

    return next();
  } catch (error) {
    return res.status(401).json({
      code: 'TOKEN_INVALID',
      message: 'Token inválido'
    });
  }
}

function toNullableNumber(value) {
  if (value === null || value === undefined || value === '') {
    return null;
  }

  const number = Number(value);

  return Number.isFinite(number) ? number : null;
}

async function saveControlIdAccessLog(log, fallbackDeviceId = null) {
  const controlIdLogId = String(log.id ?? '').trim();
  const controlIdUserId = String(log.user_id ?? '').trim();
  const deviceId = String(log.device_id ?? fallbackDeviceId ?? '').trim();
  const logTime = Number(log.time);

  if (!/^\d+$/.test(controlIdLogId) || !Number.isFinite(logTime)) {
    return false;
  }

  const accessTime = new Date(logTime * 1000);

  const result = await pool.query(
    `
    INSERT INTO control_id_access_logs (
      control_id_log_id,
      control_id_user_id,
      device_id,
      event,
      access_time,
      identifier_id,
      portal_id,
      identification_rule_id,
      card_value,
      qrcode_value,
      pin_value,
      confidence,
      mask,
      log_type_id,
      component_id,
      raw
    )
    VALUES (
      $1, $2, $3, $4, $5,
      $6, $7, $8, $9, $10,
      $11, $12, $13, $14, $15, $16
    )
    ON CONFLICT (control_id_log_id) DO NOTHING
    RETURNING id
    `,
    [
      controlIdLogId,
      /^\d+$/.test(controlIdUserId) ? controlIdUserId : null,
      deviceId || null,
      toNullableNumber(log.event),
      accessTime,
      toNullableNumber(log.identifier_id),
      toNullableNumber(log.portal_id),
      toNullableNumber(log.identification_rule_id),
      String(log.card_value ?? ''),
      String(log.qrcode_value ?? ''),
      String(log.pin_value ?? ''),
      toNullableNumber(log.confidence),
      toNullableNumber(log.mask),
      toNullableNumber(log.log_type_id),
      toNullableNumber(log.component_id),
      log
    ]
  );

  return result.rowCount > 0;
}

function adminMiddleware(req, res, next) {
  if (!req.user || req.user.role !== 'admin') {
    return res.status(403).json({
      message: 'Acesso permitido apenas para administradores',
    });
  }

  next();
}

function formatAppUser(user) {
  const controlIdUserId = Number(user.control_id_user_id || 0);

  return {
    id: user.id,
    name: user.name,
    email: user.email,
    cpf: user.cpf,
    phone: user.phone,

    birth_date: user.birth_date,
    birthDate: user.birth_date,

    role: user.role,
    active: user.active,

    control_id_user_id: controlIdUserId,
    controlIdUserId: controlIdUserId,

    photo_url: controlIdUserId > 0
      ? `/facial/users/${controlIdUserId}/face`
      : null,
    photoUrl: controlIdUserId > 0
      ? `/facial/users/${controlIdUserId}/face`
      : null,

    zip_code: user.zip_code,
    zipCode: user.zip_code,

    street: user.street,
    number: user.number,
    complement: user.complement,
    neighborhood: user.neighborhood,
    city: user.city,
    state: user.state,

    approved: user.approved,
    approval_status: user.approval_status,
    approvalStatus: user.approval_status,

    reviewed_at: user.reviewed_at,
    reviewedAt: user.reviewed_at,

    reviewed_by: user.reviewed_by,
    reviewedBy: user.reviewed_by,

    review_note: user.review_note,
    reviewNote: user.review_note,
  };
}

async function createFacialUserForDependent(dependent) {
  const session = await getFacialSession();

  const parentResult = await pool.query(
    `
    SELECT control_id_user_id
    FROM app_users
    WHERE id = $1
    `,
    [dependent.app_user_id]
  );

  const parentControlIdUserId = parentResult.rows[0]?.control_id_user_id;

  if (!parentControlIdUserId) {
    throw new Error('Usuário titular não possui control_id_user_id');
  }

  const registration = `DEP-${parentControlIdUserId}-${dependent.id}`;

  const response = await axios.post(
    `${process.env.FACIAL_BASE_URL}/create_objects.fcgi?session=${encodeURIComponent(session)}`,
    {
      object: 'users',
      values: [
        {
          name: dependent.name,
          registration,
          password: '',
          salt: '',
          begin_time: 0,
          end_time: 0,
        },
      ],
    },
    {
      timeout: 15000,
    }
  );

  const ids = response.data?.ids;

  if (!Array.isArray(ids) || !ids[0]) {
    throw new Error(
      `Control iD não retornou ID do usuário dependente: ${JSON.stringify(response.data)}`
    );
  }

  return Number(ids[0]);
}


function normalizeUserRowForReturn(user) {
  return {
    ...user,
    control_id_user_id: user.control_id_user_id || 0
  };
}

app.get('/health', (req, res) => {
  res.json({
    status: 'online'
  });
});

app.post('/auth/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    const normalizedEmail =
      typeof email === 'string'
        ? email.trim().toLowerCase()
        : null;

    console.log('Tentativa de login:', normalizedEmail);

    if (!normalizedEmail || !password) {
      await createAuditEvent({
        actorType: 'anonymous',
        action: 'auth.login.missing_credentials',
        entityType: 'authentication',
        result: 'denied',
        req,
        metadata: {
          emailProvided: Boolean(normalizedEmail),
          passwordProvided: Boolean(password),
        },
      });

      return res.status(400).json({
        message: 'Email e senha são obrigatórios',
      });
    }

    const result = await pool.query(
      `
        SELECT
          id,
          name,
          email,
          cpf,
          phone,
          birth_date,
          password_hash,
          role,
          active,
          COALESCE(control_id_user_id, 0) AS control_id_user_id,
          zip_code,
          street,
          number,
          complement,
          neighborhood,
          city,
          state,
          session_version,
          approved,
          approval_status,
          reviewed_at,
          reviewed_by,
          review_note,
          active
        FROM app_users
        WHERE LOWER(email) = LOWER($1)
          AND active = true
      `,
      [normalizedEmail]
    );

    console.log('Usuários encontrados:', result.rowCount);

    if (result.rowCount === 0) {
      await createAuditEvent({
        actorType: 'anonymous',
        action: 'auth.login.user_not_found',
        entityType: 'authentication',
        result: 'denied',
        req,
        metadata: {
          emailDomain: normalizedEmail.includes('@')
            ? normalizedEmail.split('@')[1]
            : null,
        },
      });

      return res.status(401).json({
        message: 'Usuário não encontrado ou inativo',
      });
    }

    const user = result.rows[0];

    const valid = checkPassword(
      password,
      user.password_hash
    );

    console.log('Senha válida:', valid);

    if (!valid) {
      await createAuditEvent({
        actorUserId: user.id,
        subjectUserId: user.id,
        actorType: 'user',
        action: 'auth.login.invalid_password',
        entityType: 'app_user',
        entityId: user.id,
        result: 'denied',
        req,
        metadata: {
          role: user.role,
        },
      });

      return res.status(401).json({
        message: 'Senha inválida',
      });
    }

    const token = jwt.sign(
      {
        id: user.id,
        email: user.email,
        role: user.role,
        session_version: user.session_version
      },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );

    await createAuditEvent({
      actorUserId: user.id,
      subjectUserId: user.id,
      actorType: 'user',
      action: 'auth.login.success',
      entityType: 'app_user',
      entityId: user.id,
      result: 'success',
      req,
      metadata: {
        role: user.role,
        controlIdLinked: user.control_id_user_id > 0,
      },
    });

    return res.json({
      token,
      user: formatAppUser(user),
    });
  } catch (error) {
    console.error('Erro no login:', error);

    try {
      await createAuditEvent({
        actorType: 'system',
        action: 'auth.login.internal_error',
        entityType: 'authentication',
        result: 'failure',
        req,
        metadata: {
          errorName: error.name || 'Error',
          errorMessage: error.message || 'Erro desconhecido',
        },
      });
    } catch (auditError) {
      console.error(
        'Erro ao registrar auditoria do login:',
        auditError
      );
    }

    return res.status(500).json({
      message: 'Erro interno no login',
      error: error.message,
    });
  }
});

app.get('/auth/me', authMiddleware, async (req, res) => {
  try {
    const result = await pool.query(
      `
        SELECT
          id,
          name,
          email,
          cpf,
          phone,
          birth_date,
          role,
          active,
          COALESCE(control_id_user_id, 0) AS control_id_user_id,
          zip_code,
          street,
          number,
          complement,
          neighborhood,
          city,
          state,
          approved,
          approval_status,
          reviewed_at,
          reviewed_by,
          review_note,
          session_version
        FROM app_users
        WHERE id = $1
          AND active = true
      `,
      [req.user.id]
    );

    if (result.rowCount === 0) {
      return res.status(404).json({
        message: 'Usuário não encontrado'
      });
    }

    return res.json(formatAppUser(result.rows[0]));

  } catch (error) {
    console.error('Erro ao buscar perfil:', error);

    return res.status(500).json({
      message: 'Erro ao buscar perfil',
      error: error.message
    });
  }
});

app.post('/users', async (req, res) => {
  const client = await pool.connect();

  try {
    const {
      name,
      email,
      password,
      cpf,
      phone,
      birth_date,
      zip_code,
      street,
      number,
      complement,
      neighborhood,
      city,
      state
    } = req.body;

    if (!name || !email || !password || !cpf || !phone || !birth_date) {
      return res.status(400).json({
        message: 'Nome, email, senha, CPF, telefone e data de nascimento são obrigatórios'
      });
    }

    if (!zip_code || !street || !number || !neighborhood || !city || !state) {
      return res.status(400).json({
        message: 'CEP, rua, número, bairro, cidade e UF são obrigatórios'
      });
    }

    const cleanCpf = String(cpf).replace(/\D/g, '');

    if (cleanCpf.length !== 11) {
      return res.status(400).json({
        message: 'CPF inválido'
      });
    }

    const cleanPhone = String(phone).replace(/\D/g, '');

    if (!/^[1-9][0-9](9[0-9]{8}|[2-8][0-9]{7})$/.test(cleanPhone)) {
      return res.status(400).json({
        message: 'Telefone inválido. Informe DDD + telefone. Ex: 51999999999'
      });
    }

    const cleanZipCode = String(zip_code).replace(/\D/g, '');

    if (cleanZipCode.length !== 8) {
      return res.status(400).json({
        message: 'CEP inválido. Informe 8 números.'
      });
    }

    const cleanState = String(state).trim().toUpperCase();

    if (cleanState.length !== 2) {
      return res.status(400).json({
        message: 'UF inválida. Informe apenas 2 letras. Ex: RS'
      });
    }

    const normalizedBirthDate = String(birth_date).trim();

    if (!/^\d{4}-\d{2}-\d{2}$/.test(normalizedBirthDate)) {
      return res.status(400).json({
        message: 'Data de nascimento inválida. Use o formato YYYY-MM-DD.'
      });
    }

    await client.query('BEGIN');

    const existingUser = await client.query(
      `
        SELECT id
        FROM app_users
        WHERE email = $1 OR cpf = $2
        LIMIT 1
      `,
      [
        String(email).toLowerCase().trim(),
        cleanCpf
      ]
    );

    if (existingUser.rowCount > 0) {
      await client.query('ROLLBACK');

      return res.status(409).json({
        message: 'Email ou CPF já cadastrado'
      });
    }

    let facialUser;

    try {
      facialUser = await createFacialUser({
        name,
        cpf: cleanCpf
      });
    } catch (facialError) {
      facialSession = null;

      await client.query('ROLLBACK');

      return res.status(502).json({
        message: 'Não foi possível criar o usuário no facial. Cadastro não concluído.',
        error: facialError.response?.data || facialError.message
      });
    }

    try {
      await addFacialUserToAccessGroup(
        facialUser.controlIdUserId,
        normalizedBirthDate
      );
    } catch (groupError) {
      facialSession = null;

      await client.query('ROLLBACK');

      return res.status(502).json({
        message: 'Usuário criado no facial, mas não foi possível adicionar ao grupo de acesso.',
        error: groupError.response?.data || groupError.message
      });
    }
    const passwordHash = hashPassword(password);

    const result = await client.query(
      `
        INSERT INTO app_users
          (
            name,
            email,
            password_hash,
            role,
            active,
            cpf,
            birth_date,
            control_id_user_id,
            phone,
            zip_code,
            street,
            number,
            complement,
            neighborhood,
            city,
            state
          )
        VALUES
          (
            $1, $2, $3, $4, true, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15
          )
        RETURNING
          id,
          name,
          email,
          role,
          active,
          cpf,
          birth_date,
          COALESCE(control_id_user_id, 0) AS control_id_user_id,
          phone,
          zip_code,
          street,
          number,
          complement,
          neighborhood,
          city,
          state
      `,
      [
        String(name).trim(),
        String(email).toLowerCase().trim(),
        passwordHash,
        'customer',
        cleanCpf,
        normalizedBirthDate,
        facialUser.controlIdUserId,
        cleanPhone,
        cleanZipCode,
        String(street).trim(),
        String(number).trim(),
        complement ? String(complement).trim() : null,
        String(neighborhood).trim(),
        String(city).trim(),
        cleanState
      ]
    );

    const user = result.rows[0];

    await client.query('COMMIT');

    const token = jwt.sign(
      {
        id: user.id,
        email: user.email,
        role: user.role
      },
      process.env.JWT_SECRET,
      {
        expiresIn: '7d'
      }
    );

    return res.status(201).json({
      token,
      user: formatAppUser(user)
    });

  } catch (error) {
    try {
      await client.query('ROLLBACK');
    } catch (_) { }

    if (error.code === '23505') {
      return res.status(409).json({
        message: 'Email ou CPF já cadastrado'
      });
    }

    return res.status(500).json({
      message: 'Erro ao criar cadastro',
      error: error.message
    });

  } finally {
    client.release();
  }
});





app.post('/app-users', authMiddleware, async (req, res) => {
  try {
    if (req.user.role !== 'admin') {
      return res.status(403).json({
        message: 'Sem permissão'
      });
    }

    const {
      name,
      email,
      password,
      cpf,
      phone,
      birth_date,
      role,
      zip_code,
      street,
      number,
      complement,
      neighborhood,
      city,
      state
    } = req.body;

    if (!name || !email || !password || !cpf || !birth_date) {
      return res.status(400).json({
        message: 'Nome, email, senha, CPF e data de nascimento são obrigatórios'
      });
    }

    if (!zip_code || !street || !number || !neighborhood || !city || !state) {
      return res.status(400).json({
        message: 'CEP, rua, número, bairro, cidade e UF são obrigatórios'
      });
    }

    const cleanCpf = String(cpf).replace(/\D/g, '');

    if (cleanCpf.length !== 11) {
      return res.status(400).json({
        message: 'CPF inválido'
      });
    }

    const cleanPhone = phone ? String(phone).replace(/\D/g, '') : null;

    if (cleanPhone && !/^[1-9][0-9](9[0-9]{8}|[2-8][0-9]{7})$/.test(cleanPhone)) {
      return res.status(400).json({
        message: 'Telefone inválido. Informe DDD + telefone. Ex: 51999999999'
      });
    }

    const cleanZipCode = String(zip_code).replace(/\D/g, '');

    if (cleanZipCode.length !== 8) {
      return res.status(400).json({
        message: 'CEP inválido. Informe 8 números.'
      });
    }

    const cleanState = String(state).trim().toUpperCase();

    if (cleanState.length !== 2) {
      return res.status(400).json({
        message: 'UF inválida. Informe apenas 2 letras. Ex: RS'
      });
    }

    const passwordHash = hashPassword(password);

    const result = await pool.query(
      `
        INSERT INTO app_users
          (
            name,
            email,
            password_hash,
            cpf,
            phone,
            birth_date,
            role,
            active,
            zip_code,
            street,
            number,
            complement,
            neighborhood,
            city,
            state
          )
        VALUES
          ($1, $2, $3, $4, $5, $6, $7, true, $8, $9, $10, $11, $12, $13, $14)
        RETURNING
          id,
          name,
          email,
          cpf,
          phone,
          birth_date,
          role,
          active,
          COALESCE(control_id_user_id, 0) AS control_id_user_id,
          zip_code,
          street,
          number,
          complement,
          neighborhood,
          city,
          state
      `,
      [
        String(name).trim(),
        String(email).toLowerCase().trim(),
        passwordHash,
        cleanCpf,
        cleanPhone,
        birth_date,
        role || 'operator',
        cleanZipCode,
        String(street).trim(),
        String(number).trim(),
        complement ? String(complement).trim() : null,
        String(neighborhood).trim(),
        String(city).trim(),
        cleanState
      ]
    );

    return res.status(201).json({
      success: true,
      user: formatAppUser(result.rows[0])
    });

  } catch (error) {
    if (error.code === '23505') {
      return res.status(409).json({
        message: 'Email ou CPF já cadastrado'
      });
    }

    return res.status(500).json({
      message: 'Erro ao criar usuário',
      error: error.message
    });
  }
});

app.put('/app-users/:id/phone', authMiddleware, async (req, res) => {
  try {
    const userId = Number(req.params.id);

    if (!Number.isInteger(userId) || userId <= 0) {
      return res.status(400).json({
        message: 'ID de usuário inválido'
      });
    }

    if (req.user.id !== userId && req.user.role !== 'admin') {
      return res.status(403).json({
        message: 'Sem permissão para alterar este usuário'
      });
    }

    const { phone } = req.body;

    if (!phone) {
      return res.status(400).json({
        message: 'Telefone é obrigatório'
      });
    }

    const cleanPhone = String(phone).replace(/\D/g, '');

    if (!/^[1-9][0-9](9[0-9]{8}|[2-8][0-9]{7})$/.test(cleanPhone)) {
      return res.status(400).json({
        message: 'Telefone inválido. Informe DDD + telefone. Ex: 51999999999'
      });
    }

    const result = await pool.query(
      `
        UPDATE app_users
        SET phone = $1
        WHERE id = $2
          AND active = true
        RETURNING
          id,
          name,
          email,
          cpf,
          phone,
          birth_date,
          role,
          active,
          COALESCE(control_id_user_id, 0) AS control_id_user_id,
          zip_code,
          street,
          number,
          complement,
          neighborhood,
          city,
          state
      `,
      [cleanPhone, userId]
    );

    if (result.rowCount === 0) {
      return res.status(404).json({
        message: 'Usuário não encontrado'
      });
    }

    return res.json({
      message: 'Telefone atualizado com sucesso',
      user: formatAppUser(result.rows[0])
    });

  } catch (error) {
    console.error('Erro ao atualizar telefone:', error);

    return res.status(500).json({
      message: 'Erro ao atualizar telefone',
      error: error.message
    });
  }
});


app.put(
  '/app-users/:id/profile-security',
  authMiddleware,
  async (req, res) => {
    const authenticatedUserId = Number(req.user.id);
    const authenticatedUserRole = req.user.role;

    const auditActorType =
      authenticatedUserRole === 'admin'
        ? 'administrator'
        : 'user';

    try {
      const userId = Number(req.params.id);

      if (!Number.isInteger(userId) || userId <= 0) {
        await safeCreateAuditEvent({
          actorUserId: Number.isInteger(authenticatedUserId)
            ? authenticatedUserId
            : null,
          actorType: auditActorType,
          action: 'profile_security.invalid_user_id',
          entityType: 'app_user',
          entityId: req.params.id,
          result: 'denied',
          req,
        });

        return res.status(400).json({
          message: 'ID de usuário inválido',
        });
      }

      if (
        authenticatedUserId !== userId &&
        authenticatedUserRole !== 'admin'
      ) {
        await safeCreateAuditEvent({
          actorUserId: authenticatedUserId,
          subjectUserId: userId,
          actorType: auditActorType,
          action: 'profile_security.permission_denied',
          entityType: 'app_user',
          entityId: userId,
          result: 'denied',
          req,
          metadata: {
            authenticatedRole: authenticatedUserRole,
          },
        });

        return res.status(403).json({
          message: 'Sem permissão para alterar este usuário',
        });
      }

      const {
        phone,
        current_password,
        new_password,
      } = req.body;

      const wantsToUpdatePhone =
        phone !== undefined &&
        phone !== null &&
        String(phone).trim() !== '';

      const wantsToUpdatePassword =
        new_password !== undefined &&
        new_password !== null &&
        String(new_password).trim() !== '';

      if (!wantsToUpdatePhone && !wantsToUpdatePassword) {
        await safeCreateAuditEvent({
          actorUserId: authenticatedUserId,
          subjectUserId: userId,
          actorType: auditActorType,
          action: 'profile_security.no_changes',
          entityType: 'app_user',
          entityId: userId,
          result: 'denied',
          req,
        });

        return res.status(400).json({
          message: 'Informe telefone e/ou nova senha para atualizar',
        });
      }

      let cleanPhone = null;

      if (wantsToUpdatePhone) {
        cleanPhone = String(phone).replace(/\D/g, '');

        const validPhone =
          /^[1-9][0-9](9[0-9]{8}|[2-8][0-9]{7})$/.test(
            cleanPhone
          );

        if (!validPhone) {
          await safeCreateAuditEvent({
            actorUserId: authenticatedUserId,
            subjectUserId: userId,
            actorType: auditActorType,
            action: 'profile_security.invalid_phone',
            entityType: 'app_user',
            entityId: userId,
            result: 'denied',
            req,
            metadata: {
              receivedDigits: cleanPhone.length,
            },
          });

          return res.status(400).json({
            message:
              'Telefone inválido. Informe DDD + telefone. Ex: 51999999999',
          });
        }
      }

      const userResult = await pool.query(
        `
          SELECT
            id,
            phone,
            password_hash
          FROM app_users
          WHERE id = $1
            AND active = true
          LIMIT 1
        `,
        [userId]
      );

      if (userResult.rowCount === 0) {
        await safeCreateAuditEvent({
          actorUserId: authenticatedUserId,
          subjectUserId: userId,
          actorType: auditActorType,
          action: 'profile_security.user_not_found',
          entityType: 'app_user',
          entityId: userId,
          result: 'denied',
          req,
        });

        return res.status(404).json({
          message: 'Usuário não encontrado',
        });
      }

      const currentUser = userResult.rows[0];

      let newPasswordHash = null;

      if (wantsToUpdatePassword) {
        if (
          !current_password ||
          String(current_password).trim().length === 0
        ) {
          await safeCreateAuditEvent({
            actorUserId: authenticatedUserId,
            subjectUserId: userId,
            actorType: auditActorType,
            action:
              'profile_security.current_password_missing',
            entityType: 'app_user',
            entityId: userId,
            result: 'denied',
            req,
          });

          return res.status(400).json({
            message:
              'Senha atual é obrigatória para alterar a senha',
          });
        }

        const validCurrentPassword = checkPassword(
          String(current_password),
          currentUser.password_hash
        );

        if (!validCurrentPassword) {
          await safeCreateAuditEvent({
            actorUserId: authenticatedUserId,
            subjectUserId: userId,
            actorType: auditActorType,
            action:
              'profile_security.current_password_invalid',
            entityType: 'app_user',
            entityId: userId,
            result: 'denied',
            req,
          });

          return res.status(401).json({
            message: 'Senha atual inválida',
          });
        }

        const normalizedNewPassword =
          String(new_password);

        if (normalizedNewPassword.length < 6) {
          await safeCreateAuditEvent({
            actorUserId: authenticatedUserId,
            subjectUserId: userId,
            actorType: auditActorType,
            action:
              'profile_security.new_password_too_short',
            entityType: 'app_user',
            entityId: userId,
            result: 'denied',
            req,
            metadata: {
              minimumLength: 6,
            },
          });

          return res.status(400).json({
            message:
              'A nova senha precisa ter pelo menos 6 caracteres',
          });
        }

        const isSamePassword = checkPassword(
          normalizedNewPassword,
          currentUser.password_hash
        );

        if (isSamePassword) {
          await safeCreateAuditEvent({
            actorUserId: authenticatedUserId,
            subjectUserId: userId,
            actorType: auditActorType,
            action: 'profile_security.password_reused',
            entityType: 'app_user',
            entityId: userId,
            result: 'denied',
            req,
          });

          return res.status(400).json({
            message:
              'A nova senha precisa ser diferente da senha atual',
          });
        }

        newPasswordHash = hashPassword(
          normalizedNewPassword
        );
      }

      const updateFields = [];
      const values = [];
      let paramIndex = 1;

      if (wantsToUpdatePhone) {
        updateFields.push(
          `phone = $${paramIndex}`
        );

        values.push(cleanPhone);
        paramIndex++;
      }

      if (wantsToUpdatePassword) {
        updateFields.push(
          `password_hash = $${paramIndex}`
        );

        values.push(newPasswordHash);
        paramIndex++;
      }

      values.push(userId);

      const result = await pool.query(
        `
          UPDATE app_users
          SET ${updateFields.join(', ')}
          WHERE id = $${paramIndex}
            AND active = true
          RETURNING
            id,
            name,
            email,
            cpf,
            phone,
            birth_date,
            role,
            active,
            COALESCE(
              control_id_user_id,
              0
            ) AS control_id_user_id,
            zip_code,
            street,
            number,
            complement,
            neighborhood,
            city,
            state
        `,
        values
      );

      if (result.rowCount === 0) {
        await safeCreateAuditEvent({
          actorUserId: authenticatedUserId,
          subjectUserId: userId,
          actorType: auditActorType,
          action: 'profile_security.update_not_applied',
          entityType: 'app_user',
          entityId: userId,
          result: 'failure',
          req,
        });

        return res.status(404).json({
          message: 'Usuário não encontrado',
        });
      }

      await safeCreateAuditEvent({
        actorUserId: authenticatedUserId,
        subjectUserId: userId,
        actorType: auditActorType,
        action: 'profile_security.updated',
        entityType: 'app_user',
        entityId: userId,
        result: 'success',
        req,
        metadata: {
          phoneUpdated: wantsToUpdatePhone,
          passwordUpdated: wantsToUpdatePassword,

          oldPhoneMasked: wantsToUpdatePhone
            ? maskPhone(currentUser.phone)
            : null,

          newPhoneMasked: wantsToUpdatePhone
            ? maskPhone(cleanPhone)
            : null,

          updatedByAdmin:
            authenticatedUserRole === 'admin',
        },
      });

      return res.json({
        message:
          wantsToUpdatePassword &&
            wantsToUpdatePhone
            ? 'Telefone e senha atualizados com sucesso'
            : wantsToUpdatePassword
              ? 'Senha atualizada com sucesso'
              : 'Telefone atualizado com sucesso',

        user: formatAppUser(result.rows[0]),
      });
    } catch (error) {
      console.error(
        'Erro ao atualizar perfil e segurança:',
        error
      );

      await safeCreateAuditEvent({
        actorUserId: Number.isInteger(
          authenticatedUserId
        )
          ? authenticatedUserId
          : null,

        subjectUserId: Number.isInteger(
          Number(req.params.id)
        )
          ? Number(req.params.id)
          : null,

        actorType: auditActorType,
        action: 'profile_security.internal_error',
        entityType: 'app_user',
        entityId: req.params.id,
        result: 'failure',
        req,
        metadata: {
          errorName: error.name || 'Error',
          errorCode: error.code || null,
        },
      });

      return res.status(500).json({
        message:
          'Erro ao atualizar perfil e segurança',
        error: error.message,
      });
    }
  }
);

app.get('/app-users/:id/dependents', authMiddleware, async (req, res) => {
  try {
    const userId = Number(req.params.id);

    if (!Number.isInteger(userId) || userId <= 0) {
      return res.status(400).json({
        message: 'ID de usuário inválido'
      });
    }

    if (!canManageUser(req, userId)) {
      return res.status(403).json({
        message: 'Sem permissão para consultar dependentes deste usuário'
      });
    }

    const result = await pool.query(
      `
      SELECT
        id,
        app_user_id,
        name,
        cpf,
        birth_date,
        relationship,
        active,
        control_id_user_id,
	face_registered,
        created_at,
        updated_at
      FROM app_user_dependents
      WHERE app_user_id = $1
      ORDER BY active DESC, name ASC
      `,
      [userId]
    );

    return res.json({
      dependents: result.rows
    });
  } catch (error) {
    console.error('Erro ao listar dependentes:', error);

    return res.status(500).json({
      message: 'Erro ao listar dependentes'
    });
  }
});


app.post('/app-users/:id/dependents', authMiddleware, async (req, res) => {
  try {
    const userId = Number(req.params.id);

    if (!Number.isInteger(userId) || userId <= 0) {
      return res.status(400).json({
        message: 'ID de usuário inválido'
      });
    }

    if (!canManageUser(req, userId)) {
      return res.status(403).json({
        message: 'Sem permissão para criar dependente para este usuário'
      });
    }

    const {
      name,
      cpf,
      birth_date,
      relationship
    } = req.body;

    const cleanName = String(name || '').trim();
    const cleanRelationship = String(relationship || '').trim();
    const cleanCpfValue = cleanCpf(cpf);
    const normalizedBirthDate = normalizeBirthDate(birth_date);

    if (!cleanName) {
      return res.status(400).json({
        message: 'Nome do dependente é obrigatório'
      });
    }

    if (!isValidCpf(cleanCpfValue)) {
      return res.status(400).json({
        message: 'CPF do dependente inválido'
      });
    }

    if (!normalizedBirthDate) {
      return res.status(400).json({
        message: 'Data de nascimento inválida'
      });
    }

    const allowedRelationships = [
      'spouse',
      'child',
      'father',
      'mother',
      'other'
    ];

    if (!allowedRelationships.includes(cleanRelationship)) {
      return res.status(400).json({
        message: 'Parentesco inválido'
      });
    }

    const insertResult = await pool.query(
      `
     INSERT INTO app_user_dependents (
       app_user_id,
       name,
       cpf,
       birth_date,
       relationship
     )
     VALUES ($1, $2, $3, $4, $5)
     RETURNING
       id,
       app_user_id,
       name,
       cpf,
       birth_date,
       relationship,
       active,
       control_id_user_id,
       face_registered,
       created_at,
       updated_at
     `,
      [
        userId,
        cleanName,
        cleanCpfValue,
        normalizedBirthDate,
        cleanRelationship
      ]
    );

    let dependent = insertResult.rows[0];

    let controlIdUserId = null;
    try {
      controlIdUserId = await createFacialUserForDependent(dependent);

      const updateResult = await pool.query(
        `
  UPDATE app_user_dependents
  SET
    control_id_user_id = $1,
    updated_at = NOW()
  WHERE id = $2
  RETURNING
    id,
    app_user_id,
    name,
    cpf,
    TO_CHAR(birth_date, 'DD/MM/YYYY') AS birth_date,
    relationship,
    active,
    control_id_user_id,
    face_registered,
    created_at,
    updated_at
  `,
        [controlIdUserId, dependent.id]
      );

      try {
        await addFacialUserToAccessGroup(
          controlIdUserId,
          dependent.birth_date
        );

        console.log('Dependente vinculado ao grupo de acesso:', {
          dependentId: dependent.id,
          controlIdUserId,
          groupId: 1
        });
      } catch (groupError) {
        console.error('Dependente criado no Control iD, mas erro ao vincular ao grupo:', {
          dependentId: dependent.id,
          controlIdUserId,
          message: groupError.message,
          response: groupError.response?.data
        });
      }

      dependent = updateResult.rows[0];
    } catch (facialError) {
      console.error('Dependente criado no banco, mas erro ao criar no Control iD:', facialError);

      const fallbackResult = await pool.query(
        `
       SELECT
         id,
         app_user_id,
         name,
         cpf,
         TO_CHAR(birth_date, 'DD/MM/YYYY') AS birth_date,
         relationship,
         active,
         control_id_user_id,
	 face_registered,
         created_at,
         updated_at
       FROM app_user_dependents
       WHERE id = $1
       `,
        [dependent.id]
      );

      dependent = fallbackResult.rows[0];
    }
    return res.status(201).json({
      message: controlIdUserId
        ? 'Familiar criado com sucesso'
        : 'Familiar criado, mas não foi possível criar no Control iD',
      dependent
    });
  } catch (error) {
    console.error('Erro ao criar dependente:', error);

    if (error.code === '23505') {
      return res.status(409).json({
        message: 'Já existe um dependente ou usuário com este CPF'
      });
    }

    return res.status(500).json({
      message: 'Erro ao criar dependente'
    });
  }
});


app.put('/app-users/:id/dependents/:dependentId', authMiddleware, async (req, res) => {
  try {
    const userId = Number(req.params.id);
    const dependentId = Number(req.params.dependentId);

    if (!Number.isInteger(userId) || userId <= 0) {
      return res.status(400).json({
        message: 'ID de usuário inválido'
      });
    }

    if (!Number.isInteger(dependentId) || dependentId <= 0) {
      return res.status(400).json({
        message: 'ID de dependente inválido'
      });
    }

    if (!canManageUser(req, userId)) {
      return res.status(403).json({
        message: 'Sem permissão para alterar este dependente'
      });
    }

    const {
      name,
      cpf,
      birth_date,
      relationship,
      active
    } = req.body;

    const cleanName = String(name || '').trim();
    const cleanRelationship = String(relationship || '').trim();
    const cleanCpfValue = cleanCpf(cpf);
    const normalizedBirthDate = normalizeBirthDate(birth_date);

    if (!cleanName) {
      return res.status(400).json({
        message: 'Nome do dependente é obrigatório'
      });
    }

    if (!isValidCpf(cleanCpfValue)) {
      return res.status(400).json({
        message: 'CPF do dependente inválido'
      });
    }

    if (!normalizedBirthDate) {
      return res.status(400).json({
        message: 'Data de nascimento inválida'
      });
    }

    const allowedRelationships = [
      'spouse',
      'child',
      'father',
      'mother',
      'other'
    ];

    if (!allowedRelationships.includes(cleanRelationship)) {
      return res.status(400).json({
        message: 'Parentesco inválido'
      });
    }

    const result = await pool.query(
      `
      UPDATE app_user_dependents
      SET
        name = $1,
        cpf = $2,
        birth_date = $3,
        relationship = $4,
        active = $5,
        updated_at = NOW()
      WHERE id = $6
        AND app_user_id = $7
      RETURNING
        id,
        app_user_id,
        name,
        cpf,
        birth_date,
        relationship,
        active,
        control_id_user_id,
	face_registered,
        created_at,
        updated_at
      `,
      [
        cleanName,
        cleanCpfValue,
        normalizedBirthDate,
        cleanRelationship,
        active === false ? false : true,
        dependentId,
        userId
      ]
    );

    if (result.rowCount === 0) {
      return res.status(404).json({
        message: 'Dependente não encontrado'
      });
    }

    return res.json({
      message: 'Dependente atualizado com sucesso',
      dependent: result.rows[0]
    });
  } catch (error) {
    console.error('Erro ao atualizar dependente:', error);

    if (error.code === '23505') {
      return res.status(409).json({
        message: 'Já existe outro cadastro com este CPF'
      });
    }

    return res.status(500).json({
      message: 'Erro ao atualizar dependente'
    });
  }
});

app.delete('/app-users/:id/dependents/:dependentId', authMiddleware, async (req, res) => {
  try {
    const userId = Number(req.params.id);
    const dependentId = Number(req.params.dependentId);

    if (!Number.isInteger(userId) || userId <= 0) {
      return res.status(400).json({
        message: 'ID de usuário inválido'
      });
    }

    if (!Number.isInteger(dependentId) || dependentId <= 0) {
      return res.status(400).json({
        message: 'ID de dependente inválido'
      });
    }

    if (!canManageUser(req, userId)) {
      return res.status(403).json({
        message: 'Sem permissão para remover este dependente'
      });
    }

    const result = await pool.query(
      `
      UPDATE app_user_dependents
      SET
        active = FALSE,
        updated_at = NOW()
      WHERE id = $1
        AND app_user_id = $2
      RETURNING id
      `,
      [dependentId, userId]
    );

    if (result.rowCount === 0) {
      return res.status(404).json({
        message: 'Dependente não encontrado'
      });
    }

    return res.json({
      message: 'Dependente removido com sucesso'
    });
  } catch (error) {
    console.error('Erro ao remover dependente:', error);

    return res.status(500).json({
      message: 'Erro ao remover dependente'
    });
  }
});

app.post('/app-users/:id/dependents/:dependentId/sync-facial', authMiddleware, async (req, res) => {
  try {
    const userId = Number(req.params.id);
    const dependentId = Number(req.params.dependentId);

    if (!Number.isInteger(userId) || userId <= 0) {
      return res.status(400).json({
        message: 'ID de usuário inválido'
      });
    }

    if (!Number.isInteger(dependentId) || dependentId <= 0) {
      return res.status(400).json({
        message: 'ID de familiar inválido'
      });
    }

    if (!canManageUser(req, userId)) {
      return res.status(403).json({
        message: 'Sem permissão para sincronizar este familiar'
      });
    }

    const dependentResult = await pool.query(
      `
      SELECT
        id,
        app_user_id,
        name,
        cpf,
        birth_date,
        relationship,
        active,
        control_id_user_id,
	face_registered
      FROM app_user_dependents
      WHERE id = $1
        AND app_user_id = $2
      `,
      [dependentId, userId]
    );

    if (dependentResult.rowCount === 0) {
      return res.status(404).json({
        message: 'Familiar não encontrado'
      });
    }

    const dependent = dependentResult.rows[0];

    if (dependent.control_id_user_id) {
      return res.status(400).json({
        message: 'Familiar já possui cadastro no Control iD'
      });
    }

    const controlIdUserId = await createFacialUserForDependent(dependent);

    const updateResult = await pool.query(
      `
      UPDATE app_user_dependents
      SET
        control_id_user_id = $1,
        updated_at = NOW()
      WHERE id = $2
      RETURNING
        id,
        app_user_id,
        name,
        cpf,
        TO_CHAR(birth_date, 'DD/MM/YYYY') AS birth_date,
        relationship,
        active,
        control_id_user_id,
	face_registered,
        created_at,
        updated_at
      `,
      [controlIdUserId, dependentId]
    );

    try {
      await addFacialUserToAccessGroup(
        controlIdUserId,
        dependent.birth_date
      );

      console.log('Dependente sincronizado vinculado ao grupo de acesso:', {
        dependentId,
        controlIdUserId,
        groupId: 1
      });
    } catch (groupError) {
      console.error('Dependente sincronizado no Control iD, mas erro ao vincular ao grupo:', {
        dependentId,
        controlIdUserId,
        message: groupError.message,
        response: groupError.response?.data
      });
    }

    return res.json({
      message: 'Familiar sincronizado com Control iD',
      dependent: updateResult.rows[0]
    });
  } catch (error) {
    console.error('Erro ao sincronizar familiar com Control iD:', error);

    return res.status(500).json({
      message: 'Erro ao sincronizar familiar com Control iD'
    });
  }
});

app.put('/users/:userId', authMiddleware, async (req, res) => {
  try {
    const userId = Number(req.params.userId);

    if (!userId || userId <= 0) {
      return res.status(400).json({
        message: 'ID de usuário inválido'
      });
    }

    if (req.user.id !== userId && req.user.role !== 'admin') {
      return res.status(403).json({
        message: 'Sem permissão para alterar este usuário'
      });
    }

    const { phone } = req.body;

    if (!phone) {
      return res.status(400).json({
        message: 'Telefone é obrigatório'
      });
    }

    const cleanPhone = String(phone).replace(/\D/g, '');

    if (!/^[1-9][0-9](9[0-9]{8}|[2-8][0-9]{7})$/.test(cleanPhone)) {
      return res.status(400).json({
        message: 'Telefone inválido. Informe DDD + telefone. Ex: 51999999999'
      });
    }

    const result = await pool.query(
      `
        UPDATE app_users
        SET phone = $1
        WHERE id = $2
          AND active = true
        RETURNING
          id,
          name,
          email,
          cpf,
          phone,
          birth_date,
          role,
          active,
          COALESCE(control_id_user_id, 0) AS control_id_user_id,
          zip_code,
          street,
          number,
          complement,
          neighborhood,
          city,
          state
      `,
      [cleanPhone, userId]
    );

    if (result.rowCount === 0) {
      return res.status(404).json({
        message: 'Usuário não encontrado'
      });
    }

    return res.json(formatAppUser(result.rows[0]));

  } catch (error) {
    console.error('Erro ao atualizar usuário:', error);

    return res.status(500).json({
      message: 'Erro ao atualizar usuário',
      error: error.message
    });
  }
});

app.patch('/app-users/:id/control-id', authMiddleware, async (req, res) => {
  try {
    const appUserId = Number(req.params.id);
    const { control_id_user_id } = req.body;

    if (!appUserId || Number.isNaN(appUserId)) {
      return res.status(400).json({
        success: false,
        message: 'ID do usuário do app inválido'
      });
    }

    if (!control_id_user_id || Number.isNaN(Number(control_id_user_id))) {
      return res.status(400).json({
        success: false,
        message: 'control_id_user_id é obrigatório'
      });
    }

    const result = await pool.query(
      `
        UPDATE app_users
        SET control_id_user_id = $1
        WHERE id = $2
        RETURNING
          id,
          name,
          email,
          cpf,
          phone,
          role,
          active,
          birth_date,
          COALESCE(control_id_user_id, 0) AS control_id_user_id,
          zip_code,
          street,
          number,
          complement,
          neighborhood,
          city,
          state
      `,
      [Number(control_id_user_id), appUserId]
    );

    if (result.rowCount === 0) {
      return res.status(404).json({
        success: false,
        message: 'Usuário do app não encontrado'
      });
    }

    return res.json({
      success: true,
      message: 'Usuário do app vinculado ao facial com sucesso',
      user: formatAppUser(result.rows[0])
    });

  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Erro ao vincular usuário do app ao facial',
      error: error.message
    });
  }
});


app.post('/app-users/:id/dependents/:dependentId/face', authMiddleware, upload.single('image'),
  async (req, res) => {
    try {
      const userId = Number(req.params.id);
      const dependentId = Number(req.params.dependentId);

      if (!Number.isInteger(userId) || userId <= 0) {
        return res.status(400).json({
          message: 'ID de usuário inválido'
        });
      }

      if (!Number.isInteger(dependentId) || dependentId <= 0) {
        return res.status(400).json({
          message: 'ID de familiar inválido'
        });
      }

      if (!canManageUser(req, userId)) {
        return res.status(403).json({
          message: 'Sem permissão para enviar foto deste familiar'
        });
      }

      if (!req.file) {
        return res.status(400).json({
          message: 'Imagem é obrigatória'
        });
      }

      const dependentResult = await pool.query(
        `
	  SELECT
	    id,
	    app_user_id,
	    name,
	    birth_date,
	    control_id_user_id
	  FROM app_user_dependents
	  WHERE id = $1
	    AND app_user_id = $2
	    AND active = TRUE
	  `,
        [dependentId, userId]
      );

      if (dependentResult.rowCount === 0) {
        return res.status(404).json({
          message: 'Familiar ativo não encontrado'
        });
      }

      let dependent = dependentResult.rows[0];

      let controlIdUserId = dependent.control_id_user_id;
      let createdFacialUserNow = false;

      if (!controlIdUserId) {
        controlIdUserId = await createFacialUserForDependent(dependent);
        createdFacialUserNow = true;

        await pool.query(
          `
	    UPDATE app_user_dependents
	    SET
	      control_id_user_id = $1,
	      updated_at = NOW()
	    WHERE id = $2
	      AND app_user_id = $3
	    `,
          [controlIdUserId, dependentId, userId]
        );

        dependent = {
          ...dependent,
          control_id_user_id: controlIdUserId,
        };
      }

      if (createdFacialUserNow) {
        try {
          await addFacialUserToAccessGroup(
            controlIdUserId,
            dependent.birth_date
          );
        } catch (groupError) {
          console.error('Erro ao vincular dependente ao grupo de acesso:', {
            controlIdUserId,
            message: groupError.message,
            response: groupError.response?.data,
          });
        }
      }

      const session = await getFacialSession();

      const timestamp = Math.floor(Date.now() / 1000);

      await axios.post(
        `${process.env.FACIAL_BASE_URL}/user_set_image.fcgi?user_id=${controlIdUserId}&timestamp=${timestamp}&match=0&session=${encodeURIComponent(session)}`,
        req.file.buffer,
        {
          headers: {
            'Content-Type': 'application/octet-stream',
            'Content-Length': req.file.buffer.length
          },
          maxBodyLength: Infinity,
          maxContentLength: Infinity,
          timeout: 30000
        }
      );

      await pool.query(
        `
	  UPDATE app_user_dependents
	  SET
	    face_registered = TRUE,
	    updated_at = NOW()
	  WHERE id = $1
	    AND app_user_id = $2
	  `,
        [dependentId, userId]
      );

      return res.json({
        message: 'Foto facial do familiar enviada com sucesso',
        control_id_user_id: controlIdUserId
      });
    } catch (error) {
      console.error('Erro ao enviar foto facial do familiar:', error);

      return res.status(500).json({
        message: 'Erro ao enviar foto facial do familiar'
      });
    }
  }
);


app.post('/facial/users', authMiddleware, async (req, res) => {
  try {
    const {
      name,
      cpf,
      birth_date
    } = req.body;

    if (!name || !cpf) {
      return res.status(400).json({
        message: 'Nome e CPF são obrigatórios'
      });
    }

    const facialUser = await createFacialUser({
      name,
      cpf
    });

    await addFacialUserToAccessGroup(
      facialUser.controlIdUserId,
      birth_date
    );

    return res.status(201).json({
      success: true,
      message: 'Usuário criado no facial',
      controlIdUserId: facialUser.controlIdUserId,
      data: facialUser.data
    });

  } catch (error) {
    facialSession = null;

    return res.status(500).json({
      success: false,
      message: 'Erro ao criar usuário no facial',
      error: error.response?.data || error.message
    });
  }
});


async function remoteAuthorizeDoor(user) {
  const session = await getFacialSession();

  return axios.post(
    `${process.env.FACIAL_BASE_URL}/remote_user_authorization.fcgi?session=${session}`,
    {
      event: 7,
      user_id: Number(user.control_id_user_id),
      user_name: user.name,
      user_image: true,
      portal_id: 1,
      actions: [
        {
          action: 'door',
          parameters: 'door=1',
        },
        {
          action: 'sec_box',
          parameters: 'id=65793,reason=7',
        },
      ],
    }
  );
}

app.post('/access/open-door', authMiddleware, async (req, res) => {
  try {
    const userId = Number(req.user.id);

    if (!Number.isInteger(userId) || userId <= 0) {
      await createAuditEvent({
        actorUserId: req.user?.id || null,
        actorType: 'user',
        action: 'access.open_door.invalid_user_id',
        entityType: 'access_control',
        result: 'denied',
        req,
        metadata: {
          userId
        }
      });

      return res.status(400).json({
        message: 'ID de usuário inválido'
      });
    }

    const result = await pool.query(
      `
        SELECT
          id,
          name,
          email,
          role,
          active,
          control_id_user_id,
          approved,
          approval_status
        FROM app_users
        WHERE id = $1
          AND active = true
        LIMIT 1
      `,
      [userId]
    );

    if (result.rowCount === 0) {
      await createAuditEvent({
        actorUserId: userId,
        actorType: 'user',
        action: 'access.open_door.user_not_found',
        entityType: 'access_control',
        result: 'denied',
        req,
        metadata: {
          userId
        }
      });

      return res.status(404).json({
        message: 'Usuário não encontrado ou inativo'
      });
    }

    const user = result.rows[0];

    const isAdmin = user.role === 'admin';
    const isApproved =
      user.approved === true &&
      user.approval_status === 'approved';

    if (!isAdmin && !isApproved) {
      await createAuditEvent({
        actorUserId: user.id,
        subjectUserId: user.id,
        actorType: 'user',
        action: 'access.open_door.not_approved',
        entityType: 'app_user',
        entityId: user.id,
        result: 'denied',
        req,
        metadata: {
          email: user.email,
          role: user.role,
          approved: user.approved,
          approval_status: user.approval_status,
        },
      });

      return res.status(403).json({
        success: false,
        message: 'Cadastro ainda não aprovado por um administrador.',
      });
    }

    if (!user.control_id_user_id || Number(user.control_id_user_id) <= 0) {
      await createAuditEvent({
        actorUserId: user.id,
        subjectUserId: user.id,
        actorType: 'user',
        action: 'access.open_door.control_id_not_linked',
        entityType: 'app_user',
        entityId: user.id,
        result: 'denied',
        req,
        metadata: {
          email: user.email,
          role: user.role,
          control_id_user_id: user.control_id_user_id
        }
      });

      return res.status(400).json({
        message: 'Usuário sem ID vinculado ao Control iD'
      });
    }

    let controlIdResponse;

    try {
      controlIdResponse = await remoteAuthorizeDoor(user);
    } catch (error) {
      const errorText = JSON.stringify(error.response?.data || error.message);

      const sessionExpired =
        error.response?.status === 401 ||
        errorText.toLowerCase().includes('session');

      if (!sessionExpired) {
        throw error;
      }

      facialSession = null;

      controlIdResponse = await remoteAuthorizeDoor(user);
    }

    await createAuditEvent({
      actorUserId: user.id,
      subjectUserId: user.id,
      actorType: 'user',
      action: 'access.open_door.success',
      entityType: 'access_control',
      entityId: user.id,
      result: 'success',
      req,
      metadata: {
        email: user.email,
        role: user.role,
        control_id_user_id: user.control_id_user_id,
        portal_id: 1,
        door: 1,
        controlIdResponse: controlIdResponse.data
      }
    });

    return res.json({
      success: true,
      message: 'Porta liberada com sucesso',
      data: controlIdResponse.data
    });

  } catch (error) {
    console.error(
      'Erro ao liberar porta:',
      error.response?.data || error.message
    );

    try {
      await createAuditEvent({
        actorUserId: req.user?.id || null,
        actorType: 'user',
        action: 'access.open_door.failure',
        entityType: 'access_control',
        result: 'failure',
        req,
        metadata: {
          errorName: error.name || 'Error',
          errorMessage: error.message || 'Erro desconhecido',
          controlIdError: error.response?.data || null
        }
      });
    } catch (auditError) {
      console.error(
        'Erro ao registrar auditoria da abertura de porta:',
        auditError
      );
    }

    facialSession = null;

    return res.status(500).json({
      success: false,
      message: 'Erro ao liberar porta',
      error: error.response?.data || error.message
    });
  }
});

app.post('/facial/users/:userId/face', authMiddleware, upload.single('image'), async (req, res) => {
  try {
    const session = await getFacialSession();
    const userId = Number(req.params.userId);

    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: 'Imagem não enviada'
      });
    }

    const imageBuffer = req.file.buffer;
    const timestamp = Math.floor(Date.now() / 1000);

    const response = await axios.post(
      `${process.env.FACIAL_BASE_URL}/user_set_image.fcgi?user_id=${userId}&timestamp=${timestamp}&match=0&session=${session}`,
      imageBuffer,
      {
        headers: {
          'Content-Type': 'application/octet-stream'
        },
        maxBodyLength: Infinity,
        maxContentLength: Infinity
      }
    );

    return res.json({
      success: true,
      message: 'Foto enviada com sucesso',
      data: response.data
    });

  } catch (error) {
    facialSession = null;

    return res.status(500).json({
      success: false,
      message: 'Erro ao enviar foto para o facial',
      error: error.response?.data || error.message
    });
  }
});

app.post('/users/:facialUserId/selfie', authMiddleware, upload.single('selfie'), async (req, res) => {
  try {
    const session = await getFacialSession();
    const facialUserId = Number(req.params.facialUserId);

    if (!Number.isInteger(facialUserId) || facialUserId <= 0) {
      return res.status(400).json({
        message: 'ID facial inválido'
      });
    }

    if (!req.file) {
      return res.status(400).json({
        message: 'Imagem não enviada'
      });
    }

    const imageBuffer = req.file.buffer;
    const timestamp = Math.floor(Date.now() / 1000);

    const response = await axios.post(
      `${process.env.FACIAL_BASE_URL}/user_set_image.fcgi?user_id=${facialUserId}&timestamp=${timestamp}&match=0&session=${session}`,
      imageBuffer,
      {
        headers: {
          'Content-Type': 'application/octet-stream'
        },
        maxBodyLength: Infinity,
        maxContentLength: Infinity
      }
    );

    const result = await pool.query(
      `
        SELECT
          id,
          name,
          email,
          cpf,
          phone,
          birth_date,
          role,
          active,
          COALESCE(control_id_user_id, 0) AS control_id_user_id,
          zip_code,
          street,
          number,
          complement,
          neighborhood,
          city,
          state
        FROM app_users
        WHERE control_id_user_id = $1
          AND active = true
        LIMIT 1
      `,
      [facialUserId]
    );

    if (result.rowCount === 0) {
      return res.json({
        success: true,
        message: 'Foto enviada com sucesso',
        data: response.data
      });
    }

    return res.json(formatAppUser(result.rows[0]));

  } catch (error) {
    facialSession = null;

    return res.status(500).json({
      message: 'Erro ao enviar foto para o facial',
      error: error.response?.data || error.message
    });
  }
});

app.get('/facial/users/:userId/face', async (req, res) => {
  try {
    const session = await getFacialSession();
    const userId = Number(req.params.userId);

    if (!Number.isInteger(userId) || userId <= 0) {
      return res.status(400).json({
        success: false,
        message: 'ID do usuário inválido'
      });
    }

    const response = await axios.get(
      `${process.env.FACIAL_BASE_URL}/user_get_image.fcgi?user_id=${userId}&session=${session}`,
      {
        responseType: 'arraybuffer',
        headers: {
          Accept: 'image/jpeg'
        },
        maxBodyLength: Infinity,
        maxContentLength: Infinity
      }
    );

    res.setHeader('Content-Type', 'image/jpeg');
    res.setHeader('Cache-Control', 'no-store');

    return res.send(Buffer.from(response.data));

  } catch (error) {
    facialSession = null;

    return res.status(404).json({
      success: false,
      message: 'Foto não encontrada no facial',
      error: error.response?.data || error.message
    });
  }
});

app.get('/marketing/banners', async (req, res) => {
  try {
    await deactivateExpiredMarketingBanners();

    const result = await pool.query(`
      SELECT id, title, active, sort_order, starts_at, ends_at,
             created_at, updated_at
      FROM marketing_banners
      WHERE active = TRUE
        AND (starts_at IS NULL OR starts_at <= NOW())
        AND (ends_at IS NULL OR ends_at > NOW())
      ORDER BY sort_order ASC, id ASC
    `);

    return res.json({
      banners: result.rows.map(formatMarketingBanner)
    });
  } catch (error) {
    console.error('Erro ao listar campanhas públicas:', error);
    return res.status(500).json({
      message: 'Erro ao carregar campanhas'
    });
  }
});

app.get('/marketing/banners/:id/image', async (req, res) => {
  try {
    const bannerId = Number(req.params.id);

    if (!Number.isInteger(bannerId) || bannerId <= 0) {
      return res.status(400).json({ message: 'ID de campanha inválido' });
    }

    const result = await pool.query(
      `
        SELECT image_data, mime_type
        FROM marketing_banners
        WHERE id = $1
        LIMIT 1
      `,
      [bannerId]
    );

    if (result.rowCount === 0) {
      return res.status(404).json({ message: 'Imagem não encontrada' });
    }

    const banner = result.rows[0];

    res.setHeader('Content-Type', banner.mime_type);
    res.setHeader('Cache-Control', 'public, max-age=3600');
    res.setHeader('Cross-Origin-Resource-Policy', 'cross-origin');

    const imageBuffer = Buffer.isBuffer(banner.image_data)
      ? banner.image_data
      : Buffer.from(banner.image_data);

    return res.send(imageBuffer);
  } catch (error) {
    console.error('Erro ao carregar imagem de campanha:', error);
    return res.status(500).json({ message: 'Erro ao carregar imagem' });
  }
});

app.get(
  '/admin/marketing/banners',
  authMiddleware,
  adminMiddleware,
  async (req, res) => {
    try {
      await deactivateExpiredMarketingBanners();

      const result = await pool.query(`
        SELECT id, title, active, sort_order, starts_at, ends_at,
               created_at, updated_at
        FROM marketing_banners
        ORDER BY sort_order ASC, id ASC
      `);

      return res.json({
        banners: result.rows.map(formatMarketingBanner)
      });
    } catch (error) {
      console.error('Erro ao listar campanhas administrativas:', error);
      return res.status(500).json({ message: 'Erro ao carregar campanhas' });
    }
  }
);

app.post(
  '/admin/marketing/banners',
  authMiddleware,
  adminMiddleware,
  upload.single('image'),
  async (req, res) => {
    try {
      if (!req.file || !req.file.buffer) {
        return res.status(400).json({ message: 'Imagem não enviada' });
      }

      const detectedMimeType = detectMarketingImageMimeType(req.file.buffer);

      if (!detectedMimeType) {
        return res.status(400).json({
          message: 'Formato inválido. Envie JPG, PNG ou WebP.'
        });
      }

      const maxImageSize = 8 * 1024 * 1024;

      if (req.file.size > maxImageSize) {
        return res.status(400).json({
          message: 'A imagem deve ter no máximo 8 MB.'
        });
      }

      const title = normalizeOptionalText(req.body?.title);

      if (title && title.length > 80) {
        return res.status(400).json({
          message: 'O título deve ter no máximo 80 caracteres.'
        });
      }

      const orderResult = await pool.query(`
        SELECT COALESCE(MAX(sort_order), -1) + 1 AS next_order
        FROM marketing_banners
      `);

      const nextOrder = Number(orderResult.rows[0]?.next_order || 0);

      const result = await pool.query(
        `
          INSERT INTO marketing_banners (
            title,
            image_data,
            mime_type,
            active,
            sort_order,
            created_by
          )
          VALUES ($1, $2, $3, TRUE, $4, $5)
          RETURNING id, title, active, sort_order, starts_at, ends_at,
                    created_at, updated_at
        `,
        [title, req.file.buffer, detectedMimeType, nextOrder, req.user.id]
      );

      return res.status(201).json({
        message: 'Campanha criada com sucesso',
        banner: formatMarketingBanner(result.rows[0])
      });
    } catch (error) {
      console.error('Erro ao criar campanha:', error);
      return res.status(500).json({ message: 'Erro ao criar campanha' });
    }
  }
);

app.put(
  '/admin/marketing/banners/order',
  authMiddleware,
  adminMiddleware,
  async (req, res) => {
    const client = await pool.connect();

    try {
      const bannerIds = Array.isArray(req.body?.banner_ids)
        ? req.body.banner_ids.map(Number)
        : [];

      const validIds = bannerIds.every(
        id => Number.isInteger(id) && id > 0
      );

      if (bannerIds.length === 0 || !validIds) {
        return res.status(400).json({
          message: 'Ordem de campanhas inválida'
        });
      }

      if (new Set(bannerIds).size !== bannerIds.length) {
        return res.status(400).json({
          message: 'A ordem não pode conter IDs repetidos'
        });
      }

      await client.query('BEGIN');

      for (let index = 0; index < bannerIds.length; index++) {
        await client.query(
          `
            UPDATE marketing_banners
            SET sort_order = $1, updated_at = NOW()
            WHERE id = $2
          `,
          [index, bannerIds[index]]
        );
      }

      await client.query('COMMIT');

      return res.json({ message: 'Ordem atualizada com sucesso' });
    } catch (error) {
      await client.query('ROLLBACK');
      console.error('Erro ao ordenar campanhas:', error);
      return res.status(500).json({ message: 'Erro ao ordenar campanhas' });
    } finally {
      client.release();
    }
  }
);

app.put(
  '/admin/marketing/banners/:id',
  authMiddleware,
  adminMiddleware,
  async (req, res) => {
    try {
      const bannerId = Number(req.params.id);

      if (!Number.isInteger(bannerId) || bannerId <= 0) {
        return res.status(400).json({ message: 'ID de campanha inválido' });
      }

      const hasActive = Object.prototype.hasOwnProperty.call(
        req.body || {},
        'active'
      );
      const hasTitle = Object.prototype.hasOwnProperty.call(
        req.body || {},
        'title'
      );
      const hasStartsAt = Object.prototype.hasOwnProperty.call(
        req.body || {},
        'starts_at'
      );
      const hasEndsAt = Object.prototype.hasOwnProperty.call(
        req.body || {},
        'ends_at'
      );

      if (!hasActive && !hasTitle && !hasStartsAt && !hasEndsAt) {
        return res.status(400).json({
          message: 'Informe os campos que deseja atualizar na campanha'
        });
      }

      if (hasActive && typeof req.body.active !== 'boolean') {
        return res.status(400).json({
          message: 'O campo active deve ser verdadeiro ou falso'
        });
      }

      if (hasTitle && req.body.title != null && typeof req.body.title !== 'string') {
        return res.status(400).json({ message: 'Título inválido' });
      }

      const cleanTitle = hasTitle
        ? String(req.body.title || '').trim()
        : null;

      if (cleanTitle && cleanTitle.length > 80) {
        return res.status(400).json({
          message: 'O título deve ter no máximo 80 caracteres'
        });
      }

      function parseScheduleDate(value) {
        if (value == null || String(value).trim() === '') return null;
        const parsed = new Date(value);
        return Number.isNaN(parsed.getTime()) ? undefined : parsed;
      }

      const parsedStartsAt = hasStartsAt
        ? parseScheduleDate(req.body.starts_at)
        : null;
      const parsedEndsAt = hasEndsAt
        ? parseScheduleDate(req.body.ends_at)
        : null;

      if (hasStartsAt && parsedStartsAt === undefined) {
        return res.status(400).json({ message: 'Data de início inválida' });
      }

      if (hasEndsAt && parsedEndsAt === undefined) {
        return res.status(400).json({ message: 'Data de término inválida' });
      }

      const currentResult = await pool.query(
        `
          SELECT starts_at, ends_at
          FROM marketing_banners
          WHERE id = $1
          LIMIT 1
        `,
        [bannerId]
      );

      if (currentResult.rowCount === 0) {
        return res.status(404).json({ message: 'Campanha não encontrada' });
      }

      const currentBanner = currentResult.rows[0];
      const effectiveStartsAt = hasStartsAt
        ? parsedStartsAt
        : currentBanner.starts_at;
      const effectiveEndsAt = hasEndsAt
        ? parsedEndsAt
        : currentBanner.ends_at;

      if (
        effectiveStartsAt &&
        effectiveEndsAt &&
        new Date(effectiveEndsAt) <= new Date(effectiveStartsAt)
      ) {
        return res.status(400).json({
          message: 'O término deve ser posterior ao início'
        });
      }

      const updates = [];
      const values = [];

      if (hasActive) {
        values.push(req.body.active);
        updates.push(`active = $${values.length}`);
      }

      if (hasTitle) {
        values.push(cleanTitle || null);
        updates.push(`title = $${values.length}`);
      }

      if (hasStartsAt) {
        values.push(parsedStartsAt);
        updates.push(`starts_at = $${values.length}`);
      }

      if (hasEndsAt) {
        values.push(parsedEndsAt);
        updates.push(`ends_at = $${values.length}`);
      }

      const now = new Date();
      const scheduleHasNotEnded =
        !effectiveEndsAt || new Date(effectiveEndsAt) > now;

      if (!hasActive && effectiveEndsAt && new Date(effectiveEndsAt) <= now) {
        values.push(false);
        updates.push(`active = $${values.length}`);
      } else if (
        !hasActive &&
        hasStartsAt &&
        parsedStartsAt &&
        scheduleHasNotEnded
      ) {
        values.push(true);
        updates.push(`active = $${values.length}`);
      }

      values.push(bannerId);
      updates.push('updated_at = NOW()');

      const result = await pool.query(
        `
          UPDATE marketing_banners
          SET ${updates.join(', ')}
          WHERE id = $${values.length}
          RETURNING id, title, active, sort_order, starts_at, ends_at,
                    created_at, updated_at
        `,
        values
      );

      if (result.rowCount === 0) {
        return res.status(404).json({ message: 'Campanha não encontrada' });
      }

      return res.json({
        message: 'Campanha atualizada com sucesso',
        banner: formatMarketingBanner(result.rows[0])
      });
    } catch (error) {
      console.error('Erro ao atualizar campanha:', error);
      return res.status(500).json({ message: 'Erro ao atualizar campanha' });
    }
  }
);

app.delete(
  '/admin/marketing/banners/:id',
  authMiddleware,
  adminMiddleware,
  async (req, res) => {
    try {
      const bannerId = Number(req.params.id);

      if (!Number.isInteger(bannerId) || bannerId <= 0) {
        return res.status(400).json({ message: 'ID de campanha inválido' });
      }

      const result = await pool.query(
        'DELETE FROM marketing_banners WHERE id = $1 RETURNING id',
        [bannerId]
      );

      if (result.rowCount === 0) {
        return res.status(404).json({ message: 'Campanha não encontrada' });
      }

      return res.json({ message: 'Campanha excluída com sucesso' });
    } catch (error) {
      console.error('Erro ao excluir campanha:', error);
      return res.status(500).json({ message: 'Erro ao excluir campanha' });
    }
  }
);

app.get('/admin/app-users', authMiddleware, adminMiddleware, async (req, res) => {
  try {
    const status = String(req.query.status || 'pending').trim().toLowerCase();
    const search = String(req.query.search || '').trim();

    const allowedStatuses = [
      'pending',
      'approved',
      'blocked',
      'rejected',
      'all',
    ];

    if (!allowedStatuses.includes(status)) {
      return res.status(400).json({
        message: 'Filtro de status inválido',
      });
    }

    const params = [];
    const where = [];

    where.push(`active = true`);
    where.push(`role <> 'admin'`);

    if (status !== 'all') {
      params.push(status);
      where.push(`approval_status = $${params.length}`);
    }

    if (search) {
      params.push(`%${search.toLowerCase()}%`);
      where.push(`
        (
          LOWER(name) LIKE $${params.length}
          OR LOWER(email) LIKE $${params.length}
          OR cpf LIKE $${params.length}
          OR phone LIKE $${params.length}
        )
      `);
    }

    const result = await pool.query(
      `
        SELECT
          id,
          name,
          email,
          cpf,
          phone,
          birth_date,
          role,
          active,
          COALESCE(control_id_user_id, 0) AS control_id_user_id,
          zip_code,
          street,
          number,
          complement,
          neighborhood,
          city,
          state,
          approved,
          approval_status,
          reviewed_at,
          reviewed_by,
          review_note
        FROM app_users
        WHERE ${where.join(' AND ')}
        ORDER BY
          CASE approval_status
            WHEN 'pending' THEN 1
            WHEN 'approved' THEN 2
            WHEN 'blocked' THEN 3
            WHEN 'rejected' THEN 4
            ELSE 5
          END,
          id DESC
      `,
      params
    );
    const users = result.rows.map(formatAppUser);
    const userIds = users.map((user) => user.id);

    let dependentsByUserId = {};

    if (userIds.length > 0) {
      const dependentsResult = await pool.query(
        `
      SELECT
        id,
        app_user_id,
        name,
        relationship,
        active,
        COALESCE(control_id_user_id, 0) AS control_id_user_id
      FROM app_user_dependents
      WHERE app_user_id = ANY($1::int[])
      ORDER BY id ASC
    `,
        [userIds]
      );

      dependentsByUserId = dependentsResult.rows.reduce((acc, dependent) => {
        const appUserId = dependent.app_user_id;
        const controlIdUserId = Number(dependent.control_id_user_id || 0);

        if (!acc[appUserId]) {
          acc[appUserId] = [];
        }

        acc[appUserId].push({
          id: dependent.id,
          app_user_id: dependent.app_user_id,
          name: dependent.name,
          relationship: dependent.relationship,
          active: dependent.active,
          control_id_user_id: controlIdUserId,
          photo_url: controlIdUserId > 0
            ? `/facial/users/${controlIdUserId}/photo`
            : null,
        });

        return acc;
      }, {});
    }

    return res.json({
      users: users.map((user) => ({
        ...user,
        dependents: dependentsByUserId[user.id] || [],
      })),
    });

    return res.json({
      users: result.rows.map(formatAppUser),
    });
  } catch (error) {
    console.error('Erro ao listar usuários admin:', error);

    return res.status(500).json({
      message: 'Erro ao listar usuários',
      error: error.message,
    });
  }
});

app.get('/admin/app-users/:id', authMiddleware, adminMiddleware, async (req, res) => {
  try {
    const userId = Number(req.params.id);

    if (!Number.isInteger(userId) || userId <= 0) {
      return res.status(400).json({
        message: 'ID de usuário inválido',
      });
    }

    const userResult = await pool.query(
      `
        SELECT
          id,
          name,
          email,
          cpf,
          phone,
          birth_date,
          role,
          active,
          COALESCE(control_id_user_id, 0) AS control_id_user_id,
          zip_code,
          street,
          number,
          complement,
          neighborhood,
          city,
          state,
          approved,
          approval_status,
          reviewed_at,
          reviewed_by,
          review_note
        FROM app_users
        WHERE id = $1
        LIMIT 1
      `,
      [userId]
    );

    if (userResult.rowCount === 0) {
      return res.status(404).json({
        message: 'Usuário não encontrado',
      });
    }

    const dependentsResult = await pool.query(
      `
        SELECT
          id,
          app_user_id,
          name,
          cpf,
          birth_date,
          relationship,
          active,
          control_id_user_id,
          created_at,
          updated_at
        FROM app_user_dependents
        WHERE app_user_id = $1
        ORDER BY id ASC
      `,
      [userId]
    );

    return res.json({
      user: formatAppUser(userResult.rows[0]),
      dependents: dependentsResult.rows,
    });
  } catch (error) {
    console.error('Erro ao buscar detalhes do usuário admin:', error);

    return res.status(500).json({
      message: 'Erro ao buscar detalhes do usuário',
      error: error.message,
    });
  }
});

app.put('/admin/app-users/:id/approval', authMiddleware, adminMiddleware, async (req, res) => {
  try {
    const userId = Number(req.params.id);

    if (!Number.isInteger(userId) || userId <= 0) {
      return res.status(400).json({
        message: 'ID de usuário inválido',
      });
    }

    const { approved, review_note } = req.body;

    if (typeof approved !== 'boolean') {
      return res.status(400).json({
        message: 'O campo approved deve ser booleano',
      });
    }

    const adminResult = await pool.query(
      `
        SELECT id, name, email
        FROM app_users
        WHERE id = $1
          AND role = 'admin'
          AND active = true
        LIMIT 1
      `,
      [req.user.id]
    );

    if (adminResult.rowCount === 0) {
      return res.status(403).json({
        message: 'Administrador não encontrado ou inativo',
      });
    }

    const adminUser = adminResult.rows[0];
    const adminName = adminUser.name || 'administrador';

    const nextStatus = approved ? 'approved' : 'blocked';

    const cleanReviewNote = typeof review_note === 'string'
      ? review_note.trim()
      : '';

    const finalReviewNote = approved
      ? `Autorizado por ${adminName}`
      : cleanReviewNote || `Bloqueado por ${adminName}`;

    const result = await pool.query(
      `
        UPDATE app_users
        SET
          approved = $2,
          approval_status = $3,
          reviewed_at = NOW(),
          reviewed_by = $4,
          review_note = $5
        WHERE id = $1
          AND role <> 'admin'
        RETURNING
          id,
          name,
          email,
          cpf,
          phone,
          birth_date,
          role,
          active,
          COALESCE(control_id_user_id, 0) AS control_id_user_id,
          zip_code,
          street,
          number,
          complement,
          neighborhood,
          city,
          state,
          approved,
          approval_status,
          reviewed_at,
          reviewed_by,
          review_note
      `,
      [
        userId,
        approved,
        nextStatus,
        req.user.id,
        finalReviewNote,
      ]
    );

    if (result.rowCount === 0) {
      return res.status(404).json({
        message: 'Usuário não encontrado ou não pode ser alterado',
      });
    }

    const updatedUser = result.rows[0];

    try {
      await createAuditEvent({
        actorUserId: req.user.id,
        subjectUserId: updatedUser.id,
        actorType: 'user',
        action: approved
          ? 'admin.app_user.approve'
          : 'admin.app_user.block',
        entityType: 'app_user',
        entityId: updatedUser.id,
        result: 'success',
        req,
        metadata: {
          actorRole: 'admin',
          targetUserEmail: updatedUser.email,
          adminName,
          approved,
          approvalStatus: updatedUser.approval_status,
          reviewNote: finalReviewNote,
        },
      });
    } catch (auditError) {
      console.error(
        'Erro ao registrar auditoria da aprovação/bloqueio:',
        auditError
      );
    }

    return res.json({
      message: approved
        ? 'Usuário aprovado com sucesso'
        : 'Usuário bloqueado com sucesso',
      user: formatAppUser(updatedUser),
    });
  } catch (error) {
    console.error('Erro ao alterar aprovação do usuário:', error);

    return res.status(500).json({
      message: 'Erro ao alterar aprovação do usuário',
      error: error.message,
    });
  }
});

app.put('/admin/app-users/:id', authMiddleware, adminMiddleware, async (req, res) => {
  try {
    const userId = Number(req.params.id);

    if (!Number.isInteger(userId) || userId <= 0) {
      return res.status(400).json({
        message: 'ID de usuário inválido',
      });
    }

    const {
      name,
      email,
      phone,
      cpf,
      birth_date,
      zip_code,
      street,
      number,
      complement,
      neighborhood,
      city,
      state,
    } = req.body;

    if (!name || !String(name).trim()) {
      return res.status(400).json({
        message: 'Nome é obrigatório',
      });
    }

    if (!email || !String(email).trim()) {
      return res.status(400).json({
        message: 'E-mail é obrigatório',
      });
    }

    const cleanEmail = String(email).trim().toLowerCase();

    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(cleanEmail)) {
      return res.status(400).json({
        message: 'E-mail inválido',
      });
    }

    const cleanPhone = String(phone || '').replace(/\D/g, '');

    if (!cleanPhone) {
      return res.status(400).json({
        message: 'Telefone é obrigatório',
      });
    }

    if (!/^[1-9][0-9](9[0-9]{8}|[2-8][0-9]{7})$/.test(cleanPhone)) {
      return res.status(400).json({
        message: 'Telefone inválido. Informe DDD + telefone. Ex: 51999999999',
      });
    }

    const cleanCpfValue = cleanCpf(cpf);

    if (!cleanCpfValue) {
      return res.status(400).json({
        message: 'CPF é obrigatório',
      });
    }

    if (!isValidCpf(cleanCpfValue)) {
      return res.status(400).json({
        message: 'CPF inválido',
      });
    }

    const cleanBirthDate = normalizeBirthDate(birth_date);

    if (!cleanBirthDate) {
      return res.status(400).json({
        message: 'Data de nascimento inválida',
      });
    }

    const cleanZipCode = String(zip_code || '').replace(/\D/g, '');

    if (cleanZipCode && cleanZipCode.length !== 8) {
      return res.status(400).json({
        message: 'CEP inválido',
      });
    }

    const cleanState = normalizeOptionalText(state)?.toUpperCase() ?? null;

    if (cleanState && !/^[A-Z]{2}$/.test(cleanState)) {
      return res.status(400).json({
        message: 'UF inválida. Informe 2 letras. Ex: RS',
      });
    }

    const duplicatedEmail = await pool.query(
      `
        SELECT id
        FROM app_users
        WHERE LOWER(email) = LOWER($1)
          AND id <> $2
        LIMIT 1
      `,
      [cleanEmail, userId]
    );

    if (duplicatedEmail.rowCount > 0) {
      return res.status(409).json({
        message: 'Este e-mail já está em uso por outro usuário',
      });
    }

    const duplicatedCpf = await pool.query(
      `
        SELECT id
        FROM app_users
        WHERE cpf = $1
          AND id <> $2
        LIMIT 1
      `,
      [cleanCpfValue, userId]
    );

    if (duplicatedCpf.rowCount > 0) {
      return res.status(409).json({
        message: 'Este CPF já está em uso por outro usuário',
      });
    }

    const result = await pool.query(
      `
        UPDATE app_users
        SET
          name = $1,
          email = $2,
          phone = $3,
          cpf = $4,
          birth_date = $5,
          zip_code = $6,
          street = $7,
          number = $8,
          complement = $9,
          neighborhood = $10,
          city = $11,
          state = $12
        WHERE id = $13
        RETURNING
          id,
          name,
          email,
          cpf,
          phone,
          birth_date,
          role,
          active,
          control_id_user_id,
          zip_code,
          street,
          number,
          complement,
          neighborhood,
          city,
          state,
          approved,
          approval_status,
          reviewed_at,
          reviewed_by,
          review_note
      `,
      [
        String(name).trim(),
        cleanEmail,
        cleanPhone,
        cleanCpfValue,
        cleanBirthDate,
        cleanZipCode || null,
        normalizeOptionalText(street),
        normalizeOptionalText(number),
        normalizeOptionalText(complement),
        normalizeOptionalText(neighborhood),
        normalizeOptionalText(city),
        cleanState,
        userId,
      ]
    );

    if (result.rowCount === 0) {
      return res.status(404).json({
        message: 'Usuário não encontrado',
      });
    }

    return res.json(result.rows[0]);
  } catch (error) {
    console.error('Erro ao atualizar usuário admin:', error);

    return res.status(500).json({
      message: 'Erro ao atualizar usuário',
    });
  }
});

app.post('/admin/app-users/:id/logout-all', authMiddleware, async (req, res) => {
  try {
    if (req.user.role !== 'admin') {
      return res.status(403).json({
        code: 'ADMIN_ONLY',
        message: 'Apenas administradores podem derrubar sessões'
      });
    }

    const userId = Number(req.params.id);

    if (!Number.isInteger(userId) || userId <= 0) {
      return res.status(400).json({
        code: 'INVALID_USER_ID',
        message: 'ID de usuário inválido'
      });
    }

    if (userId === req.user.id) {
      return res.status(400).json({
        code: 'CANNOT_LOGOUT_SELF',
        message: 'Você não pode derrubar sua própria sessão por aqui'
      });
    }

    const result = await pool.query(
      `
      UPDATE app_users
      SET session_version = session_version + 1
      WHERE id = $1
      RETURNING
        id,
        name,
        email,
        session_version
      `,
      [userId]
    );

    if (result.rowCount === 0) {
      return res.status(404).json({
        code: 'USER_NOT_FOUND',
        message: 'Usuário não encontrado'
      });
    }

    return res.json({
      message: 'Sessões derrubadas com sucesso',
      user: result.rows[0]
    });
  } catch (error) {
    console.error('Erro ao derrubar sessões:', error);

    return res.status(500).json({
      code: 'LOGOUT_ALL_ERROR',
      message: 'Erro ao derrubar sessões do usuário'
    });
  }
});

app.post('/admin/sync-access-logs', authMiddleware, async (req, res) => {
  try {
    if (req.user.role !== 'admin') {
      return res.status(403).json({
        message: 'Apenas administradores podem sincronizar logs'
      });
    }

    if (!facialSession) {
      await loginFacial();
    }

    let response;

    try {
      response = await axios.post(
        `${process.env.FACIAL_BASE_URL}/load_objects.fcgi?session=${facialSession}`,
        {
          object: 'access_logs'
        },
        {
          timeout: 30000
        }
      );
    } catch (error) {
      console.error(
        'Erro ao carregar logs. Tentando renovar sessão:',
        error.response?.data || error.message
      );

      await loginFacial();

      response = await axios.post(
        `${process.env.FACIAL_BASE_URL}/load_objects.fcgi?session=${facialSession}`,
        {
          object: 'access_logs'
        },
        {
          timeout: 30000
        }
      );
    }

    const logs = response.data?.access_logs || [];

    let inserted = 0;

    for (const log of logs) {
      const controlIdLogId = Number(log.id);
      const controlIdUserId = Number(log.user_id);
      const accessTime = new Date(Number(log.time) * 1000);

      if (!Number.isFinite(controlIdLogId) || !Number.isFinite(log.time)) {
        continue;
      }

      const result = await pool.query(
        `
        INSERT INTO control_id_access_logs (
          control_id_log_id,
          control_id_user_id,
          device_id,
          event,
          access_time,
          identifier_id,
          portal_id,
          identification_rule_id,
          card_value,
          qrcode_value,
          pin_value,
          confidence,
          mask,
          log_type_id,
          component_id,
          raw
        )
        VALUES (
          $1, $2, $3, $4, $5,
          $6, $7, $8, $9, $10,
          $11, $12, $13, $14, $15, $16
        )
        ON CONFLICT (control_id_log_id) DO NOTHING
        RETURNING id
        `,
        [
          controlIdLogId,
          Number.isFinite(controlIdUserId) ? controlIdUserId : null,
          log.device_id ?? null,
          log.event ?? null,
          accessTime,
          log.identifier_id ?? null,
          log.portal_id ?? null,
          log.identification_rule_id ?? null,
          String(log.card_value ?? ''),
          String(log.qrcode_value ?? ''),
          String(log.pin_value ?? ''),
          log.confidence ?? null,
          log.mask ?? null,
          log.log_type_id ?? null,
          log.component_id ?? null,
          log
        ]
      );

      if (result.rowCount > 0) {
        inserted++;
      }
    }

    return res.json({
      message: 'Logs sincronizados com sucesso',
      received: logs.length,
      inserted
    });
  } catch (error) {
    console.error(
      'Erro ao sincronizar logs de acesso:',
      error.response?.data || error.message
    );

    return res.status(500).json({
      message: 'Erro ao sincronizar logs de acesso'
    });
  }
});

app.get('/access-logs', authMiddleware, async (req, res) => {
  try {
    const appUserId = Number(req.user.id);

    if (!Number.isInteger(appUserId) || appUserId <= 0) {
      return res.status(401).json({
        message: 'Usuário inválido'
      });
    }

    const userResult = await pool.query(
      `
      SELECT
        id,
        name,
        control_id_user_id
      FROM app_users
      WHERE id = $1
      `,
      [appUserId]
    );

    if (userResult.rowCount === 0) {
      return res.status(404).json({
        message: 'Usuário não encontrado'
      });
    }

    const user = userResult.rows[0];

    const dependentsResult = await pool.query(
      `
      SELECT
        id,
        name,
        control_id_user_id
      FROM app_user_dependents
      WHERE app_user_id = $1
        AND control_id_user_id IS NOT NULL
      `,
      [appUserId]
    );

    const people = [];

    if (user.control_id_user_id) {
      people.push({
        app_user_id: user.id,
        dependent_id: null,
        name: user.name,
        type: 'titular',
        control_id_user_id: Number(user.control_id_user_id),
        photo_url: `/facial/users/${user.control_id_user_id}/face`
      });
    }

    for (const dependent of dependentsResult.rows) {
      people.push({
        app_user_id: appUserId,
        dependent_id: dependent.id,
        name: dependent.name,
        type: 'dependente',
        control_id_user_id: Number(dependent.control_id_user_id),
        photo_url: `/facial/users/${dependent.control_id_user_id}/face`
      });
    }

    const controlIds = people
      .map(person => person.control_id_user_id)
      .filter(id => Number.isInteger(id) && id > 0);

    if (controlIds.length === 0) {
      return res.json({
        access_logs: []
      });
    }

    const logsResult = await pool.query(
      `
      SELECT
        l.id,
        l.control_id_log_id,
        l.control_id_user_id,
        l.event,
        l.access_time,
        l.device_id,
        l.identifier_id,
        l.portal_id,
        l.confidence
      FROM control_id_access_logs l
      WHERE l.control_id_user_id = ANY($1::bigint[])
      ORDER BY l.access_time DESC
      LIMIT 100
      `,
      [controlIds]
    );

    const logs = logsResult.rows.map(log => {
      const person = people.find(
        item => Number(item.control_id_user_id) === Number(log.control_id_user_id)
      );

      return {
        id: log.id,
        control_id_log_id: log.control_id_log_id,
        control_id_user_id: log.control_id_user_id,

        person_name: person?.name || 'Usuário não identificado',
        person_type: person?.type || 'desconhecido',
        person_photo_url: person?.photo_url || null,
        dependent_id: person?.dependent_id || null,

        event: log.event,
        event_label: formatAccessEvent(log.event),

        access_time: log.access_time,
        device_id: log.device_id,
        identifier_id: log.identifier_id,
        portal_id: log.portal_id,
        confidence: log.confidence
      };
    });

    return res.json({
      access_logs: logs
    });
  } catch (error) {
    console.error('Erro ao consultar histórico de acessos:', error);

    return res.status(500).json({
      message: 'Erro ao consultar histórico de acessos'
    });
  }
});

function formatAccessEvent(event) {
  const eventNumber = Number(event);

  switch (eventNumber) {
    case 1:
      return 'Equipamento inválido';

    case 2:
      return 'Parâmetros de identificação inválidos';

    case 3:
      return 'Não identificado';

    case 4:
      return 'Identificação pendente';

    case 5:
      return 'Tempo de identificação esgotado';

    case 6:
      return 'Acesso negado';

    case 7:
      return 'Acesso presencial';

    case 8:
      return 'Acesso pendente';

    case 9:
      return 'Usuário não é administrador';

    case 10:
      return 'Acesso via APP';

    case 11:
      return 'Acesso por botoeira';

    case 12:
      return 'Acesso pela interface web';

    case 13:
      return 'Desistência de entrada';

    case 14:
      return 'Sem resposta';

    case 15:
      return 'Acesso pela interfonia';

    default:
      return 'Evento de acesso';
  }
}



app.post('/api/notifications/dao', async (req, res) => {
  try {
    const expectedDeviceId = String(
      process.env.FACIAL_DEVICE_ID ?? ''
    ).trim();

    const receivedDeviceId = String(
      req.body?.device_id ?? ''
    ).trim();

    if (
      !expectedDeviceId ||
      receivedDeviceId !== expectedDeviceId
    ) {
      console.warn('Notificação recusada: device_id inválido');
      return res.sendStatus(403);
    }

    const changes = Array.isArray(req.body?.object_changes)
      ? req.body.object_changes
      : [];

    const accessLogChanges = changes.filter(change => {
      return (
        change?.object === 'access_logs' &&
        change?.type === 'inserted' &&
        change?.values
      );
    });

    let inserted = 0;

    for (const change of accessLogChanges) {
      const saved = await saveControlIdAccessLog(
        change.values,
        receivedDeviceId
      );

      if (saved) {
        inserted++;
      }
    }

    console.log('Monitor Control iD:', {
      received: changes.length,
      accessLogs: accessLogChanges.length,
      inserted
    });

    return res.sendStatus(200);
  } catch (error) {
    console.error('Erro no Monitor Control iD:', error);
    return res.sendStatus(500);
  }
});


app.post('/api/notifications/device_is_alive', (req, res) => {
  const expectedDeviceId = String(
    process.env.FACIAL_DEVICE_ID || ''
  ).trim();

  const receivedDeviceId = String(
    req.body && req.body.device_id
      ? req.body.device_id
      : ''
  ).trim();

  if (!expectedDeviceId) {
    console.error('FACIAL_DEVICE_ID não configurado');
    return res.sendStatus(503);
  }

  if (receivedDeviceId !== expectedDeviceId) {
    console.warn('Heartbeat recusado: device_id inválido');
    return res.sendStatus(403);
  };

  return res.sendStatus(200);
});

app.listen(process.env.PORT || 3000, () => {
  console.log('API rodando...');
});
