-- ============================================
-- Sunny Days — Supabase Schema
-- Run this in the Supabase SQL Editor once
-- ============================================

-- User app profiles: tracks which Sunny Days app a user first signed up from
CREATE TABLE IF NOT EXISTS public.user_app_profiles (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    app_id      TEXT NOT NULL,  -- e.g. "brewscan", "pawdiac", "pocket_crystals"
    created_at  TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, app_id)
);

ALTER TABLE public.user_app_profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage their own app profiles"
    ON public.user_app_profiles FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE OR REPLACE FUNCTION public.record_source_app_profile()
RETURNS TRIGGER AS $$
DECLARE
    source_app TEXT;
BEGIN
    source_app := COALESCE(NEW.raw_user_meta_data->>'source_app', 'unknown');

    INSERT INTO public.user_app_profiles (user_id, app_id)
    VALUES (NEW.id, source_app)
    ON CONFLICT (user_id, app_id) DO NOTHING;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created_record_source_app ON auth.users;

CREATE TRIGGER on_auth_user_created_record_source_app
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.record_source_app_profile();

-- BrewScan: saved scans
CREATE TABLE IF NOT EXISTS public.brewscan_saved_scans (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    pod_id      TEXT,
    pod_name    TEXT,
    pod_line    TEXT,
    notes       TEXT,
    created_at  TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.brewscan_saved_scans ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage their own scans"
    ON public.brewscan_saved_scans FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- BrewScan: favorite pods
CREATE TABLE IF NOT EXISTS public.brewscan_favorite_pods (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    pod_id      TEXT NOT NULL,
    created_at  TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, pod_id)
);

ALTER TABLE public.brewscan_favorite_pods ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage their own favorites"
    ON public.brewscan_favorite_pods FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- BrewScan: saved recipes
CREATE TABLE IF NOT EXISTS public.brewscan_saved_recipes (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    recipe_id   TEXT NOT NULL,
    created_at  TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, recipe_id)
);

ALTER TABLE public.brewscan_saved_recipes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage their own saved recipes"
    ON public.brewscan_saved_recipes FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);
