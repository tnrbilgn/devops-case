from flask import Flask, request, jsonify
import psycopg2
import redis
import os

app = Flask(__name__)

POSTGRES_HOST = "my-postgresql"
POSTGRES_PORT = 5432
POSTGRES_DB = "customdatabase"
POSTGRES_USER = "customuser"
POSTGRES_PASSWORD = "custompassword"

try:


    print(f"PostgreSQL Config - Host: {os.getenv('POSTGRES_HOST')}, Port: {os.getenv('POSTGRES_PORT')}, DB: {os.getenv('POSTGRES_DB')}, User: {os.getenv('POSTGRES_USER')}")
    print(f"Redis Config - Host: {os.getenv('REDIS_HOST')}, Port: {os.getenv('REDIS_PORT')}")

    db_conn = psycopg2.connect(
        host=POSTGRES_HOST,
        port=POSTGRES_PORT,
        database=POSTGRES_DB,
        user=POSTGRES_USER,
        password=POSTGRES_PASSWORD,
    )

    cursor = db_conn.cursor()
    cursor.execute("SELECT 1;")
    cursor.close()
    print("PostgreSQL bağlantısı başarılı.")
except Exception as e:
    print(f"PostgreSQL bağlantı hatası: {e}")
    db_conn = None

try:
    redis_client = redis.StrictRedis(
        host=os.getenv("REDIS_HOST", "127.0.0.1"),
        port=int(os.getenv("REDIS_PORT", 6379)),
        decode_responses=True
    )
    redis_client.ping()
    print("Redis bağlantısı başarılı.")
except Exception as e:
    print(f"Redis bağlantı hatası: {e}")
    redis_client = None

@app.route('/set', methods=['POST'])
def set_value():
    if not db_conn or not redis_client:

        return jsonify({'error': 'Bağlantı problemi var. Lütfen kontrol edin.'}), 500

    data = request.json
    key, value = data.get('key'), data.get('value')
    if not key or not value:
        return jsonify({'error': 'Key and value required'}), 400

    try:
        redis_client.set(key, value)  # Redis'e Yaz
        db_conn.rollback()
        cursor = db_conn.cursor()
        cursor.execute("INSERT INTO cache (key, value) VALUES (%s, %s) ON CONFLICT (key) DO UPDATE SET value = %s", (key, value, value))
        db_conn.commit()  # PostgreSQL'e Yaz
        cursor.close()
        return jsonify({'message': f'{key} set to {value}'}), 200
    except Exception as e:
        db_conn.rollback()
        return jsonify({'error': f'Hata: {e}'}), 500

@app.route('/health', methods=['GET'])
def health_check():
    health_status = {}

    # PostgreSQL sağlığı kontrolü
    try:
        cursor = db_conn.cursor()
        cursor.execute("SELECT 1;")
        cursor.close()
        health_status['PostgreSQL'] = 'healthy'
    except Exception as e:
        health_status['PostgreSQL'] = f'unhealthy: {e}'

    # Redis sağlığı kontrolü
    try:
        redis_client.ping()
        health_status['Redis'] = 'healthy'
    except Exception as e:
        health_status['Redis'] = f'unhealthy: {e}'

    return jsonify(health_status), 200 if all(value == 'healthy' for value in health_status.values()) else 500

@app.route('/get', methods=['GET'])
def get_ok():
    return "tamam", 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
