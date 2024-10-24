### Guide: Test with Kafka

Start by uncommenting the Redpanda service in the `compose.yml` file along with the datagen service. Then, start the services:

```bash
docker compose up -d
```

Next, create the required objects in Materialize:

1. **Connect to Materialize:**
    ```bash
    psql -h localhost -p 6877 -U mz_system materialize
    ```

2. **Create Kafka Connection:**
    ```sql
    CREATE CONNECTION redpanda_kafka TO KAFKA (
        BROKER = 'redpanda:9092',
        SECURITY PROTOCOL = 'PLAINTEXT'
    );
    ```

3. **Create Kafka Source:**
    ```sql
    CREATE SOURCE mz_datagen_source
    FROM KAFKA CONNECTION redpanda_kafka (
        TOPIC 'mz_datagen_test'
    ) FORMAT JSON;
    ```

4. **Create a Materialized View:**
    ```sql
    CREATE MATERIALIZED VIEW datagen_view AS
        SELECT
            (data->>'id')::int AS id,
            data->>'name' AS name
        FROM mz_datagen_source;
    ```

5. **Create an Index:**
    > [!TIP]
    > Running `SUBSCRIBE` on an unindexed view can be slow and resource-intensive as it requires a full scan of the view/table/source.

    ```sql
    CREATE INDEX datagen_view_idx ON datagen_view (id);
    ```

6. **Verify Data Flow:**
    ```sql
    SELECT * FROM datagen_view LIMIT 5;
    ```

Then follow the steps in the [README.md](./README.md) file to test this with `SUBSCRIBE`.

## Cleanup

To stop the services and remove volumes:
```bash
docker compose down -v
```
