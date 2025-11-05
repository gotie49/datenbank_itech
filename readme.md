Datenbank Challenge I ITech

- Run the build script to setup the database and test data: 
```bash
./build.sh
```

- Connect:
```bash
docker exec -it postgres psql -U admin -d krautundrueben
``` 
- Start Container:
```bash
docker start -ai postgres
```

- Entity Relationship Diagram (including Rezept Tables):
![ERD](docs/entity_relationship_diagram.png)

- TODO:
 - [ ] ERD aktualisieren
 - [ ] queries.sql in DDL, DCL, DML und DQL unterteilen
 - [x] skript für automatischen aufsetzen der db mit docker befehlen
