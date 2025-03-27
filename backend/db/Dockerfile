FROM postgres:15

# Create the necessary directories
RUN mkdir -p /docker-entrypoint-initdb.d

# Copy the entire sql directory with all its contents
COPY sql /docker-entrypoint-initdb.d/sql

# Copy initialization script to the correct location and make it executable
COPY init.sh /docker-entrypoint-initdb.d/
RUN chmod +x /docker-entrypoint-initdb.d/init.sh

# Expose PostgreSQL port
EXPOSE 5432