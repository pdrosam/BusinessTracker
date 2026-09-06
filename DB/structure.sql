DO $$ BEGIN
    CREATE TYPE public.user_role AS ENUM ('merchant', 'promoter', 'administrator');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  role public.user_role DEFAULT 'promoter' NOT NULL,
  is_active BOOLEAN DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS public.states (
  id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name TEXT NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS public.clients (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  rif TEXT NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS public.clients_states (
  client_id UUID REFERENCES public.clients(id) ON DELETE CASCADE,
  state_id INTEGER REFERENCES public.states(id) ON DELETE CASCADE,
  PRIMARY KEY (client_id, state_id)
);

CREATE TABLE IF NOT EXISTS public.products (
  id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  client_id UUID REFERENCES public.clients(id) ON DELETE CASCADE,
  units_per_package INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS public.merchant_reports (
  id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  submitted_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  state_id INTEGER REFERENCES public.states(id),
  salesman_name TEXT NOT NULL,
  merchant_id UUID REFERENCES public.profiles(id),
  zone TEXT NOT NULL,
  stablishment TEXT NOT NULL,
  client_id UUID REFERENCES public.clients(id)
);

CREATE TABLE IF NOT EXISTS public.promoter_reports (
  id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  submitted_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  state_id INTEGER REFERENCES public.states(id),
  promoter_id UUID REFERENCES public.profiles(id),
  zone TEXT NOT NULL,
  stablishment TEXT NOT NULL,
  client_id UUID REFERENCES public.clients(id)
);

CREATE TABLE IF NOT EXISTS public.merchant_report_details (
  report_id INTEGER REFERENCES public.merchant_reports(id) ON DELETE CASCADE,
  product_id INTEGER REFERENCES public.products(id) ON DELETE CASCADE,
  salesfloor_inventory INTEGER NOT NULL CHECK (salesfloor_inventory >= 0),
  stockroom_inventory INTEGER NOT NULL CHECK (stockroom_inventory >= 0),
  total_units INTEGER NOT NULL CHECK (total_units = salesfloor_inventory + stockroom_inventory),
  PRIMARY KEY (report_id, product_id)
);

CREATE TABLE IF NOT EXISTS public.promoter_report_details (
  report_id INTEGER REFERENCES public.promoter_reports(id) ON DELETE CASCADE,
  product_id INTEGER REFERENCES public.products(id) ON DELETE CASCADE,
  initial_inventory INTEGER NOT NULL CHECK (initial_inventory >= 0),
  final_inventory INTEGER NOT NULL CHECK (final_inventory >= 0),
  total_sales INTEGER NOT NULL CHECK (total_sales = initial_inventory - final_inventory),
  PRIMARY KEY (report_id, product_id)
);

CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
DECLARE
  is_admin BOOLEAN;
BEGIN
  SELECT role = 'administrator' INTO is_admin
  FROM public.profiles
  WHERE id = auth.uid();
  
  RETURN coalesce(is_admin, false);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Administrators can view all profiles" ON public.profiles;
DROP POLICY IF EXISTS "Administrators can insert profiles" ON public.profiles;
DROP POLICY IF EXISTS "Administrators can update profiles" ON public.profiles;
DROP POLICY IF EXISTS "Administrators can delete profiles" ON public.profiles;

CREATE POLICY "Users can view their own profile"
  ON public.profiles FOR SELECT
  TO authenticated
  USING ( auth.uid() = id );

CREATE POLICY "Administrators can view all profiles"
  ON public.profiles FOR SELECT
  TO authenticated
  USING ( public.is_admin() );

CREATE POLICY "Administrators can insert profiles"
  ON public.profiles FOR INSERT
  TO authenticated
  WITH CHECK ( public.is_admin() );

CREATE POLICY "Administrators can update profiles"
  ON public.profiles FOR UPDATE
  TO authenticated
  USING ( public.is_admin() )
  WITH CHECK ( public.is_admin() );

CREATE POLICY "Administrators can delete profiles"
  ON public.profiles FOR DELETE
  TO authenticated
  USING ( public.is_admin() );

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, first_name, last_name, role)
  VALUES (
    new.id, 
    COALESCE(new.raw_user_meta_data->>'first_name', 'Unknown'),
    COALESCE(new.raw_user_meta_data->>'last_name', 'Unknown'),
    'promoter'
  );
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- hash password function
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE OR REPLACE FUNCTION public.create_user_by_admin(
    email_input TEXT,
    password_input TEXT,
    first_name TEXT,
    last_name TEXT,
    user_role public.user_role
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    new_user_id UUID := gen_random_uuid();
    hashed_password TEXT;
    result json;
BEGIN
    IF NOT public.is_admin() THEN
      RAISE EXCEPTION 'Access Denied: Only administrators can create users.';
    END IF;

    -- Hash the password using pgcrypto
    hashed_password := crypt(password_input, gen_salt('bf'));

    INSERT INTO auth.users (
        id,
        instance_id,
        email,
        encrypted_password,
        email_confirmed_at,
        confirmation_token,
        recovery_token,
        email_change,
        email_change_token_new,
        raw_app_meta_data,
        raw_user_meta_data,
        aud,
        role,
        created_at,
        updated_at
    ) VALUES (
        new_user_id,
        '00000000-0000-0000-0000-000000000000',
        email_input,
        hashed_password,
        NOW(),
        '',
        '',
        '',
        '',
        '{"provider":"email","providers":["email"]}',
        json_build_object('first_name', first_name, 'last_name', last_name, 'email_verified', true),
        'authenticated',
        'authenticated',
        NOW(),
        NOW()
    );

    UPDATE auth.users
    SET confirmation_token = COALESCE(confirmation_token, ''),
        recovery_token = COALESCE(recovery_token, ''),
        email_change = COALESCE(email_change, ''),
        email_change_token_new = COALESCE(email_change_token_new, '')
    WHERE id = new_user_id;

    -- 3. Insert into auth.identities (FIXED: Added id and provider_id)
    INSERT INTO auth.identities (
        id,
        provider_id, 
        user_id,
        identity_data,
        provider,
        last_sign_in_at,
        created_at,
        updated_at
    ) VALUES (
        gen_random_uuid(),   -- Unique ID for the identity record
        new_user_id::text,   -- maps to the user ID for email auth
        new_user_id,
        json_build_object('sub', new_user_id::text, 'email', email_input),
        'email',
        NOW(),
        NOW(),
        NOW()
    );

    UPDATE public.profiles 
    SET role = user_role 
    WHERE id = new_user_id;

    result := json_build_object('status', 'success', 'user_id', new_user_id);
    RETURN result;
EXCEPTION
    WHEN unique_violation THEN
        RAISE EXCEPTION 'A user with this email already exists.';
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Failed to create user: %', SQLERRM;
END;
$$;