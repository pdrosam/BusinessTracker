-- ==============================================
-- TABLAS
-- ==============================================

CREATE TABLE "profiles" (
  "id" UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  "first_name" TEXT NOT NULL,
  "last_name" TEXT NOT NULL,
  "role" TEXT NOT NULL CHECK ("role" IN ('merchant', 'promotor', 'administrator')),
  "is_active" BOOLEAN DEFAULT TRUE
);

CREATE TABLE "states" (
  "id" INTEGER GENERATED ALWAYS AS IDENTITY,
  "name" TEXT NOT NULL UNIQUE,
  PRIMARY KEY ("id")
);

CREATE TABLE "clients" (
  "id" UUID DEFAULT gen_random_uuid(),
  "name" TEXT NOT NULL UNIQUE,
  "rif" TEXT NOT NULL UNIQUE,
  PRIMARY KEY ("id")
);

CREATE TABLE "clients_states" (
  "client_id" UUID,
  "state_id" INTEGER,
  PRIMARY KEY ("client_id", "state_id"),
  FOREIGN KEY ("client_id") REFERENCES "clients"("id"),
  FOREIGN KEY ("state_id") REFERENCES "states"("id")
);

CREATE TABLE "products" (
  "id" INTEGER GENERATED ALWAYS AS IDENTITY,
  "name" TEXT NOT NULL UNIQUE,
  "client_id" UUID,
  "units_per_package" INTEGER NOT NULL,
  PRIMARY KEY ("id"),
  FOREIGN KEY ("client_id") REFERENCES "clients"("id")
);

CREATE TABLE "merchant_reports" (
  "id" INTEGER GENERATED ALWAYS AS IDENTITY,
  "submitted_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  "state_id" INTEGER,
  "salesman_name" TEXT NOT NULL,
  "merchant_id" UUID,
  "zone" TEXT NOT NULL,
  "stablishment" TEXT NOT NULL,
  "client_id" UUID,
  PRIMARY KEY ("id"),
  FOREIGN KEY ("state_id") REFERENCES "states"("id"),
  FOREIGN KEY ("merchant_id") REFERENCES "profiles"("id"),
  FOREIGN KEY ("client_id") REFERENCES "clients"("id")
);

CREATE TABLE "promotor_reports" (
  "id" INTEGER GENERATED ALWAYS AS IDENTITY,
  "submitted_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  "state_id" INTEGER,
  "salesman_name" TEXT NOT NULL,
  "promotor_id" UUID NOT NULL,
  "zone" TEXT NOT NULL,
  "stablishment" TEXT NOT NULL,
  "client_id" UUID,
  PRIMARY KEY ("id"),
  FOREIGN KEY ("state_id") REFERENCES "states"("id"),
  FOREIGN KEY ("promotor_id") REFERENCES "profiles"("id"),
  FOREIGN KEY ("client_id") REFERENCES "clients"("id")
);

CREATE TABLE "merchant_report_details" (
  "report_id" INTEGER,
  "product_id" INTEGER,
  "salesfloor_inventory" INTEGER NOT NULL CHECK ("salesfloor_inventory" >= 0),
  "stockroom_inventory" INTEGER NOT NULL CHECK ("stockroom_inventory" >= 0),
  PRIMARY KEY ("report_id", "product_id"),
  FOREIGN KEY ("report_id") REFERENCES "merchant_reports"("id"),
  FOREIGN KEY ("product_id") REFERENCES "products"("id")
);

CREATE TABLE "promotor_report_details" (
  "report_id" INTEGER,
  "product_id" INTEGER,
  "initial_inventory" INTEGER NOT NULL CHECK ("initial_inventory" >= 0),
  "final_inventory" INTEGER NOT NULL CHECK ("final_inventory" >= 0),
  "total_sales" INTEGER NOT NULL CHECK ("total_sales" = "initial_inventory" - "final_inventory"),
  PRIMARY KEY ("report_id", "product_id"),
  FOREIGN KEY ("report_id") REFERENCES "promotor_reports"("id"),
  FOREIGN KEY ("product_id") REFERENCES "products"("id")
);

-- ==============================================
-- TRIGGER: crear profile automáticamente al registrarse
-- ==============================================

create function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, first_name, last_name, role)
  values (
    new.id,
    new.raw_user_meta_data ->> 'first_name',
    new.raw_user_meta_data ->> 'last_name',
    new.raw_user_meta_data ->> 'role'
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- ==============================================
-- ROW LEVEL SECURITY (permisos de lectura y escritura)
-- ==============================================

alter table profiles enable row level security;
alter table states enable row level security;
alter table clients enable row level security;
alter table clients_states enable row level security;
alter table products enable row level security;
alter table merchant_reports enable row level security;
alter table promotor_reports enable row level security;
alter table merchant_report_details enable row level security;
alter table promotor_report_details enable row level security;

-- PROFILES: cada usuario ve solo su propio perfil (para saber su rol al iniciar sesión)
create policy "select_own_profile"
on profiles for select
to authenticated
using (auth.uid() = id);

-- CATALOGOS: lectura para cualquier usuario autenticado (mercaderista o promotora)
create policy "select_states" on states for select to authenticated using (true);
create policy "select_clients" on clients for select to authenticated using (true);
create policy "select_clients_states" on clients_states for select to authenticated using (true);
create policy "select_products" on products for select to authenticated using (true);

-- MERCHANT_REPORTS: solo el mercaderista dueño de la sesión puede insertar/leer sus reportes
create policy "insert_own_merchant_report"
on merchant_reports for insert
to authenticated
with check (
  merchant_id = auth.uid()
  and exists (select 1 from profiles where id = auth.uid() and role = 'merchant' and is_active = true)
);

create policy "select_own_merchant_report"
on merchant_reports for select
to authenticated
using (merchant_id = auth.uid());

-- PROMOTOR_REPORTS: solo la promotora dueña de la sesión puede insertar/leer sus reportes
create policy "insert_own_promotor_report"
on promotor_reports for insert
to authenticated
with check (
  promotor_id = auth.uid()
  and exists (select 1 from profiles where id = auth.uid() and role = 'promotor' and is_active = true)
);

create policy "select_own_promotor_report"
on promotor_reports for select
to authenticated
using (promotor_id = auth.uid());

-- MERCHANT_REPORT_DETAILS: solo detalles de reportes propios
create policy "insert_own_merchant_report_details"
on merchant_report_details for insert
to authenticated
with check (report_id in (select id from merchant_reports where merchant_id = auth.uid()));

create policy "select_own_merchant_report_details"
on merchant_report_details for select
to authenticated
using (report_id in (select id from merchant_reports where merchant_id = auth.uid()));

-- PROMOTOR_REPORT_DETAILS: solo detalles de reportes propios
create policy "insert_own_promotor_report_details"
on promotor_report_details for insert
to authenticated
with check (report_id in (select id from promotor_reports where promotor_id = auth.uid()));

create policy "select_own_promotor_report_details"
on promotor_report_details for select
to authenticated
using (report_id in (select id from promotor_reports where promotor_id = auth.uid()));
