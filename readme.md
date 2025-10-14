Datenbank Challenge I ITech

- Step 1: 
```bash
docker volume create pgdata

docker run -d --name postgres -e POSTGRES_USER=admin -e POSTGRES_PASSWORD=admin -e POSTGRES_DB=krautundrueben -v pgdata:/var/lib/postgresql/data -p 5432:5432 postgres:17
```
- Step 2 (inside repository): 
```bash
docker exec -i postgres psql -U admin -d krautundrueben < psqlinit.sql
docker exec -i postgres psql -U admin -d krautundrueben < initdata.sql
```
- Connect:
```bash
docker exec -it postgres psql -U admin -d krautundrueben
``` 
- Start Container:
```bash
docker start -ai postgres
```
