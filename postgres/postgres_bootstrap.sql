CREATE SCHEMA ecommerce;
-- Create the ecommerce schema if it doesn't exist
CREATE SCHEMA IF NOT EXISTS "ecommerce";
DO $$
DECLARE i INT;
table_name TEXT;
BEGIN -- Loop 2000 times
FOR i IN 1..2000 LOOP -- Create dynamic table name
table_name := 'products_' || i;
-- Create table
EXECUTE format(
  '
            CREATE TABLE "ecommerce"."%s" (
                "id" int PRIMARY KEY,
                "username" varchar,
                "email" varchar,
                "password" varchar,
                "age" int,
                "status" int
            )',
  table_name
);
-- Set REPLICA IDENTITY
EXECUTE format(
  'ALTER TABLE "ecommerce"."%s" REPLICA IDENTITY FULL',
  table_name
);
-- Insert one row with the table number as the ID
EXECUTE format(
  '
            INSERT INTO "ecommerce"."%s" 
            VALUES (%s, ''user_%s'', ''user_%s@example.com'', ''pass_%s'', 25, 1)',
  table_name,
  i,
  i,
  i,
  i
);
END LOOP;
END $$;
ALTER SYSTEM
SET wal_level = logical;
ALTER ROLE postgres WITH REPLICATION;
-- Update the publication to include all tables
DROP PUBLICATION IF EXISTS mz_source;
CREATE PUBLICATION mz_source FOR ALL TABLES;