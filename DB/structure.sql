CREATE TABLE "profiles" (
  "id" UUID DEFAULT gen_random_uuid(), 
  "first_name" TEXT NOT NULL,
  "last_name" TEXT NOT NULL,
  "role" TEXT NOT NULL CHECK ("role" IN ('merchant', 'promotor', 'administrator')),
  "is_active" BOOLEAN DEFAULT TRUE,
  PRIMARY KEY ("id")
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
  "promotor_id" TEXT NOT NULL,
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
  "total_units" INTEGER NOT NULL CHECK ("total_units" = "salesfloor_inventory" + "stockroom_inventory"),
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
