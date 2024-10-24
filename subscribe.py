#!/usr/bin/env python3

import os
import psycopg2
from dotenv import load_dotenv

load_dotenv()

# Connection configuration
dsn = "user={} password={} host={} dbname={} port={} options='--welcome_message=off'".format(
    os.getenv('MTZ_USER', 'mz_system'),
    os.getenv('MTZ_PASSWORD', 'materialize'),
    os.getenv('MTZ_HOST', 'localhost'),
    os.getenv('MTZ_DATABASE', 'materialize'),
    os.getenv('MTZ_PORT', '6877')
)

def main():
    # Create connection
    conn = psycopg2.connect(dsn)
    conn.autocommit = True

    with conn:  # This ensures the transaction stays open
        with conn.cursor() as cur:
            cur.execute(
                "DECLARE c CURSOR FOR SUBSCRIBE datagen_view WITH (SNAPSHOT = FALSE, PROGRESS = TRUE);"
            )
            print("Waiting for updates...")
            while True:
                cur.execute("FETCH ALL c WITH (timeout='1s');")
                for row in cur:
                    if len(row) > 1 and row[1] and str(row[1]).lower() == 'true':
                        continue
                    print(row)

if __name__ == "__main__":
    main()
