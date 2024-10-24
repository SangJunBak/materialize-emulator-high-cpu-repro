# Materialize Kafka Data Generation Demo

This demo sets up a pipeline using Materialize, Redpanda (Kafka), and the Materialize datagen tool to generate and process streaming data.

## Setup

1. Create the following directory structure:
```
your-project/
├── docker-compose.yml
└── schemas/
    └── schema.json
```

2. Start the services:
```bash
docker compose up -d
```

3. Wait for all services to be healthy (usually takes about 30-45 seconds)
```bash
docker compose ps
```

## Connect to Materialize

Connect to the Materialize instance:
```bash
psql -h localhost -p 6877 -U mz_system materialize
```

## Create Required Objects

1. Create the Kafka connection:
```sql
CREATE CONNECTION redpanda_kafka TO KAFKA (
    BROKER = 'redpanda:9092',
    SECURITY PROTOCOL = 'PLAINTEXT'
);
```

2. Create the Kafka source:
```sql
CREATE SOURCE mz_datagen_source
FROM KAFKA CONNECTION redpanda_kafka (
    TOPIC 'mz_datagen_test'
) FORMAT JSON;
```

3. Create a materialized view:
```sql
CREATE MATERIALIZED VIEW datagen_view AS
    SELECT
        (data->>'id')::int AS id,
        data->>'name' AS name
    FROM mz_datagen_source;
```

4. Create an index to optimize queries (optional):
```sql
CREATE INDEX datagen_view_idx ON datagen_view (id);
```

## Verify Setup

Check that data is flowing:
```sql
SELECT * FROM datagen_view LIMIT 5;
```

Check the number of records:
```sql
SELECT count(*) FROM datagen_view;
```

## Configuration Details

- The datagen service will generate:
  - 10,024 records (`-n 10024`)
  - With a write interval of 5000ms (`-w 5000`)
  - In JSON format (`-f json`)
  - Using the schema defined in `/schemas/schema.json`
  - Data will include:
    - An incremental ID
    - A randomly generated username

## Troubleshooting

If you don't see data flowing:
1. Check service health:
```bash
docker compose ps
```

2. Check Redpanda logs:
```bash
docker compose logs redpanda
```

3. Check datagen logs:
```bash
docker compose logs datagen
```

4. Verify Kafka topic:
```sql
SHOW SOURCES;
```

## Using `SUBSCRIBE`

You can use the `SUBSCRIBE` command to see the data as it flows in:
```sql
COPY (SUBSCRIBE mz_datagen_source) TO STDOUT;
-- Subscribe with no snapshot:
COPY (SUBSCRIBE mz_datagen_source WITH(SNAPSHOT FALSE)) TO STDOUT;
```

## Using `SUBSCRIBE` with Python and psycopg2

Setup virtual environment:
```bash
python3 -m venv venv
source venv/bin/activate
pip install psycopg2-binary python-dotenv
```

Run the the `subscribe.py` script:
```bash
python subscribe.py
```

Output:

```py
Waiting for updates...
(Decimal('1729773847000'), False, 1, 310, 'Jon')
(Decimal('1729773852000'), False, 1, 311, 'Jane')
(Decimal('1729773857000'), False, 1, 312, 'Laurie')
```

![simple-example-subscribe](https://github.com/user-attachments/assets/6c92dc54-3cae-4605-ab2a-2885dad0bb86)

## Cleanup

Stop the services:
```bash
docker compose down -v
```
