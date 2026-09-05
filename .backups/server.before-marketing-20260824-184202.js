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

  // Aceita YYYY-MM-DD
  if (/^\d{4}-\d{2}-\d{2}$/.test(text)) {
    return text;
  }

  // Aceita DD/MM/YYYY
  if (/^\d{2}\/\d{2}\/\d{4}$/.test(text)) {
    const [day, month, year] = text.split('/');
    return `${year}-${month}-${day}`;
  }

  return null;
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

function authMiddleware(req, res, next) {
  const authHeader = req.headers.authorization;

  if (!authHeader) {
    return res.status(401).json({
      message: 'Token ausente'
    });
  }

  const [, token] = authHeader.split(' ');

  try {
    req.user = jwt.verify(token, process.env.JWT_SECRET);
    return next();
  } catch {
    return res.status(401).json({
      message: 'Token inválido'
    });
  }
}

function formatAppUser(user) {
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

    control_id_user_id: user.control_id_user_id,
    controlIdUserId: user.control_id_user_id,

    zip_code: user.zip_code,
    zipCode: user.zip_code,

    street: user.street,
    number: user.number,
    complement: user.complement,
    neighborhood: user.neighborhood,
    city: user.city,
    state: user.state
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
	  approved,
	  approval_status,
	  reviewed_at,
	  reviewed_by,
 	  review_note
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
      },
      process.env.JWT_SECRET,
      {
        expiresIn: '8h',
      }
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
          state
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
    } catch (_) {}

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


app.post('/app-users/:id/dependents/:dependentId/face',authMiddleware,upload.single('image'),
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
      user_image: false,
      portal_id: 1,
      actions: [
        {
          action: 'door',
          parameters: 'door=1'
        }
      ]
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
          control_id_user_id
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

app.listen(process.env.PORT || 3000, () => {
  console.log('API rodando...');
});
