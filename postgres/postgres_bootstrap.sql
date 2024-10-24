ALTER SYSTEM SET wal_level = logical;
ALTER ROLE postgres WITH REPLICATION;

CREATE SCHEMA ecommerce;

CREATE TABLE "ecommerce"."products" (
  "id" int PRIMARY KEY,
  "username" varchar,
  "email" varchar,
  "password" varchar,
  "age" int,
  "status" int
);

-- Enable REPLICA for both tables
ALTER TABLE "ecommerce"."products" REPLICA IDENTITY FULL;

-- Create publication on the created tables
CREATE PUBLICATION mz_source FOR TABLE "ecommerce"."products";
