FROM python:3.12-slim

ENV DEBIAN_FRONTEND=noninteractive

# Base deps + unixodbc (runtime) and unixodbc-dev (build for pyodbc)
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl gnupg apt-transport-https ca-certificates \
    unixodbc unixodbc-dev libgssapi-krb5-2 build-essential && \
    rm -rf /var/lib/apt/lists/*

# Microsoft repo for msodbcsql18 (ODBC Driver 18 for SQL Server)
RUN curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o /usr/share/keyrings/ms-packages.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/ms-packages.gpg] https://packages.microsoft.com/debian/12/prod bookworm main" > /etc/apt/sources.list.d/microsoft.list && \
    apt-get update && ACCEPT_EULA=Y apt-get install -y --no-install-recommends msodbcsql18 && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY webapp/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY webapp /app

EXPOSE 8000
CMD ["uvicorn", "main:app", "--host=0.0.0.0", "--port=8000"]
