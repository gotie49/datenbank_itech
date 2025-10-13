Datenbank Challenge I ITech

- Step 1: 
```bash
docker volume create pgdata

docker run -d \
  --name postgres \
  -e POSTGRES_USER=admin \
  -e POSTGRES_PASSWORD=admin \
  -e POSTGRES_DB=appdb \
  -v pgdata:/var/lib/postgresql/data \
  -p 5432:5432 \
  postgres:17
```

- Step 2: 
Run `psqlinit.sql` followed by `initdata.sql`
