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

> [!TIP]
> `CREATE INDEX` creates an in-memory index on a source, view, or materialized view. For more information, see the [Materialize documentation](https://materialize.com/docs/sql/create-index/).
> In Materialize, indexes store query results in memory within a [cluster](https://materialize.com/docs/concepts/clusters/), and keep these results incrementally updated as new data arrives. By making up-to-date results available in memory, indexes can help [optimize query performance](https://materialize.com/docs/transform-data/optimization/), both when serving results and maintaining resource-heavy operations like joins.

4. Create an index to optimize queries (optional):
```sql
CREATE INDEX datagen_view_idx ON datagen_view (id);
```

> [!TIP]
> Running `SUBSCRIBE` on an unindexed view can be slow and resource-intensive as it requires a full scan of the view/table/source.

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

## Debugging Materialize

### Check Container Status
```bash
# Check all containers status
docker compose ps

# Check container health
docker compose ps materialized
```

### View Logs
```bash
# View Materialize logs
docker compose logs materialized

# Follow logs in real-time
docker compose logs -f materialized | grep -v 'No such file or directory'

# View last 100 lines
docker compose logs --tail=100 materialized

# Check all services logs
docker compose logs
```

### Resource Management
1. Docker Desktop Resource Limits
   - Open Docker Desktop → Settings → Resources
   - Recommended minimum settings:
     - CPUs: 6
     - Memory: 12GB
     - Swap: 1GB
   - Apply & Restart Docker Desktop

2. Check Resource Usage
```bash
# View container resource usage
docker stats materialized
```

### Check Source Status

If Materialize is not receiving data from the source, you will not see any data when running `SUBSCRIBE` without a snapshot. To check the source status, run the following queries:

```sql
-- Get the source name:
SHOW SOURCES;

-- Check source status:
SELECT * FROM mz_internal.mz_source_statuses
WHERE name = 'SOURCE_NAME';
```

## Cleanup

Stop the services:
```bash
docker compose down -v
```
