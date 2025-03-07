#!/bin/bash

# Enable strict mode for better security
set -euo pipefail

echo "Starting Geocitizen error correction..."

# PostgreSQL Database Configuration
echo "Checking PostgreSQL..."

# Restore PostgreSQL authentication if necessary
echo "Checking pg_hba.conf file..."
PG_HBA_PATH=$(sudo find /etc/postgresql -name "pg_hba.conf")

if grep -q "scram-sha-256" "$PG_HBA_PATH"; then
    echo "Changing authentication from scram-sha-256 to md5 in pg_hba.conf..."
    sudo sed -i 's/scram-sha-256/md5/g' "$PG_HBA_PATH"
    sudo systemctl restart postgresql
else
    echo "Authentication in pg_hba.conf is already configured correctly."
fi

# Restore PostgreSQL user password if necessary
echo "Checking access for 'postgres' user..."
if sudo -u postgres psql -c "SELECT 1;" &>/dev/null; then
    echo "The 'postgres' user has correct access."
else
    echo "Resetting password for 'postgres' user..."
    sudo -u postgres psql -c "ALTER USER postgres PASSWORD 'admin123';"
fi

# Check if the database user exists
if sudo -u postgres psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='geocitizen_user'" | grep -q 1; then
    echo "'geocitizen_user' already exists."
else
    echo "Creating 'geocitizen_user' in PostgreSQL..."
    sudo -u postgres psql -c "CREATE USER geocitizen_user WITH PASSWORD '1234';"
fi

# Check if the database exists
if sudo -u postgres psql -tAc "SELECT 1 FROM pg_database WHERE datname='geocitizen'" | grep -q 1; then
    echo "The 'geocitizen' database already exists."
else
    echo "Creating 'geocitizen' database..."
    sudo -u postgres psql -c "CREATE DATABASE geocitizen OWNER geocitizen_user;"
fi

# Grant permissions to the user if needed
echo "Checking 'geocitizen_user' permissions..."
if sudo -u postgres psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='geocitizen_user' AND rolcanlogin;" | grep -q 1; then
    echo "'geocitizen_user' permissions are already set."
else
    echo "Granting permissions to 'geocitizen_user'..."
    sudo -u postgres psql -c "ALTER DATABASE geocitizen OWNER TO geocitizen_user;"
    sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE geocitizen TO geocitizen_user;"
fi

# Ensure PostgreSQL service is running
echo "Checking PostgreSQL service status..."
if systemctl is-active --quiet postgresql; then
    echo "PostgreSQL is running correctly."
else
    echo "Restarting PostgreSQL..."
    sudo systemctl restart postgresql
    sudo systemctl enable postgresql
fi

# Apache Tomcat Configuration
echo "Checking Apache Tomcat..."

# Check if Tomcat has the required files
if [ -f "/opt/tomcat/apache-tomcat-9.0.100/bin/setclasspath.sh" ]; then
    echo "'setclasspath.sh' file is present."
else
    echo "Restoring 'setclasspath.sh'..."
    cp /opt/tomcat/apache-tomcat-9.0.100/bin/catalina.sh /opt/tomcat/apache-tomcat-9.0.100/bin/setclasspath.sh
    chmod +x /opt/tomcat/apache-tomcat-9.0.100/bin/setclasspath.sh
fi

# Check if Tomcat is running
if systemctl is-active --quiet tomcat; then
    echo "Tomcat is running correctly."
else
    echo "Restarting Tomcat..."
    sudo systemctl daemon-reload
    sudo systemctl restart tomcat
    sudo systemctl enable tomcat
fi

# Fix file permissions on deployed WAR
echo "Checking permissions on citizen.war..."
if [ "$(stat -c "%a" /opt/tomcat/apache-tomcat-9.0.100/webapps/citizen.war)" == "755" ]; then
    echo "Permissions on citizen.war are correct."
else
    echo "Adjusting permissions on citizen.war..."
    sudo chmod 755 /opt/tomcat/apache-tomcat-9.0.100/webapps/citizen.war
fi


# General Fixes
echo "Applying general fixes..."

# Enable all Actuator endpoints if not already enabled
if grep -q "management.endpoints.web.exposure.include=" /opt/tomcat/apache-tomcat-9.0.100/conf/catalina.properties; then
    echo "Actuator endpoints are already enabled."
else
    echo "Enabling all Actuator endpoints..."
    sudo sed -i 's/#management.endpoints.web.exposure.include=.*/management.endpoints.web.exposure.include=*/' /opt/tomcat/apache-tomcat-9.0.100/conf/catalina.properties
fi

# Open firewall ports if necessary
echo "Checking firewall ports..."
if sudo ufw status | grep -q "8080/tcp.*ALLOW"; then
    echo "Port 8080 is already open in the firewall."
else
    echo "Opening port 8080 in the firewall..."
    sudo ufw allow 8080/tcp
fi

if sudo ufw status | grep -q "5432/tcp.*ALLOW"; then
    echo "Port 5432 is already open in the firewall."
else
    echo "Opening port 5432 in the firewall..."
    sudo ufw allow 5432/tcp
fi

# Restart services only if changes were made
if ! systemctl is-active --quiet postgresql || ! systemctl is-active --quiet tomcat; then
    echo "Restarting services..."
    sudo systemctl restart postgresql
    sudo systemctl restart tomcat
fi

#Created By Dj-Amaz0nCs
echo "Geocitizen successfully fixed and running."
