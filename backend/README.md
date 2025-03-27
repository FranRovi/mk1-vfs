# VFS API

Virtual File System API for managing directories and files.


## Deployment

Create a `.env` file in the root directory with the following variables:

```bash
API_PORT=
DB_NAME=
DB_USER=
DB_PASSWORD=
```

Start the services in detached mode:

```bash
docker compose up --build -d
```

Load the [mock data](test/mock_data.md):

```bash
source .env
source test/db_utils.sh
run_query_f test/load_mock_data.sql
```


## Testing

```bash
python -m pytest test/test_routes.py -v
```

