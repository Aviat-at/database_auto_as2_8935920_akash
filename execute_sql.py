import os
import mysql.connector

# Retrieve credentials from environment variables
DB_CONFIG = {
    "host": os.getenv("DB_HOST"),
    "user": os.getenv("DB_USER"),
    "password": os.getenv("DB_PASSWORD"),
    "database": os.getenv("DB_NAME")
}

def execute_sql_file(sql_file):
    try:
        conn = mysql.connector.connect(**DB_CONFIG)
        cursor = conn.cursor()

        with open(sql_file, "r") as file:
            sql_script = file.read()
            for statement in sql_script.split(";"):
                if statement.strip():
                    cursor.execute(statement)

        conn.commit()
        print(f"{sql_file} executed successfully!")

    except mysql.connector.Error as err:
        print(f"Error executing {sql_file}: {err}")

    finally:
        cursor.close()
        conn.close()

if __name__ == "__main__":
    for sql_file in os.listdir():
        if sql_file.endswith(".sql"):
            execute_sql_file(sql_file)
