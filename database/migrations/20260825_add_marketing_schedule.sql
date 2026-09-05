ALTER TABLE public.marketing_banners
  ADD COLUMN IF NOT EXISTS starts_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS ends_at TIMESTAMPTZ;

CREATE INDEX IF NOT EXISTS idx_marketing_banners_public_schedule
  ON public.marketing_banners (active, starts_at, ends_at, sort_order);

GRANT SELECT, INSERT, UPDATE, DELETE
  ON TABLE public.marketing_banners
  TO api_user;
