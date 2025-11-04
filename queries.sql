/*Fachliche Anforderungen an die SQL-Statements */

/* Zutaten eines Rezepts abrufen: Stellt eine Abfrage bereit, mit der alle Zutaten eines ausgewählten Rezepts sowie den jeweiligen Mengenangaben angezeigt werden. */
/* Gerrit */
SELECT REZEPT.name, ZUTAT.bezeichnung, REZEPT_ZUTAT.menge 
    FROM REZEPT_ZUTAT 
    JOIN REZEPT ON REZEPT.rezept_id = REZEPT_ZUTAT.rezept_id
    JOIN ZUTAT ON ZUTAT.zutatennr = REZEPT_ZUTAT.zutatennr
    WHERE REZEPT.name IN ('$REZEPT-NAME');

/* Rezepte mit bestimmter Zutat finden: Zeigt alle Rezepte an, die eine ausgewählte Zutat enthalten. */
/* Gerrit */
SELECT REZEPT.name, REZEPT.beschreibung, ZUTAT.bezeichnung, REZEPT_ZUTAT.menge 
    FROM REZEPT 
    JOIN REZEPT_ZUTAT ON REZEPT.rezept_id = REZEPT_ZUTAT.rezept_id
    JOIN ZUTAT ON REZEPT_ZUTAT.zutatennr = ZUTAT.zutatennr
    WHERE ZUTAT.bezeichnung IN ('$ZUTAT-BEZEICHNUNG');

/* Anzahl Rezepte nach Ernährungskategorie: Entwickelt eine Abfrage, die anzeigt wie viele Rezepte pro Ernährungskategorie (z. B. vegan, vegetarisch) vorhanden sind. */
/* Gerrit */
SELECT ERNAEHRUNGSKATEGORIE.bezeichnung, COUNT(*) as anzahl_rezepte
    FROM REZEPT 
    JOIN ERNAEHRUNGSKATEGORIE ON REZEPT.kategorie_id = ERNAEHRUNGSKATEGORIE.kategorie_id
    GROUP BY ERNAEHRUNGSKATEGORIE.bezeichnung;

/* Durchschnittliche Nährwerte berechnen: Berechnet die durchschnittlichen Nährwerte (Kalorien, Proteine, Kohlenhydrate, Fett etc.) pro Bestellung für alle Bestellungen eines Kunden. */
/* Gerrit */
SELECT BESTELLUNG.bestellnr, 
    SUM(ZUTAT.kalorien * BESTELLUNGZUTAT.menge) as kalorien, 
    SUM(ZUTAT.kohlenhydrate * BESTELLUNGZUTAT.menge) as kohlenhydrate, 
    SUM(ZUTAT.protein * BESTELLUNGZUTAT.menge) as protein 
FROM BESTELLUNG
    JOIN BESTELLUNGZUTAT ON BESTELLUNG.bestellnr = BESTELLUNGZUTAT.bestellnr
    JOIN ZUTAT ON BESTELLUNGZUTAT.zutatennr = ZUTAT.zutatennr
    WHERE BESTELLUNG.kundennr IN ('$BESTELLUNG-KUNDENNR')
    GROUP BY BESTELLUNG.bestellnr;

/* Unverknüpfte Zutaten identifizieren: Findet alle Zutaten, die bisher keinem Rezept zugeordnet sind. */
/* Gerrit */
SELECT ZUTAT.zutatennr, ZUTAT.bezeichnung 
    FROM ZUTAT
    LEFT JOIN REZEPT_ZUTAT ON REZEPT_ZUTAT.zutatennr = ZUTAT.zutatennr
    WHERE REZEPT_ZUTAT.zutatennr IS NULL;

/* Rezepte nach Kalorienmenge filtern: Stellt alle Rezepte zusammen, die eine bestimmte maximale Kalorienmenge nicht überschreiten. */
/* Gerrit */
SELECT REZEPT.rezept_id, SUM(ZUTAT.kalorien * REZEPT_ZUTAT.menge) AS rezept_kalorien 
    FROM REZEPT
    JOIN REZEPT_ZUTAT ON REZEPT_ZUTAT.rezept_id  = REZEPT.rezept_id
    JOIN ZUTAT ON ZUTAT.zutatennr = REZEPT_ZUTAT.zutatennr
    GROUP BY REZEPT.rezept_id
    HAVING SUM(ZUTAT.kalorien * REZEPT_ZUTAT.menge) < $KALORIENMENGE;

/* Rezepte mit wenigen Zutaten finden: Wählt alle Rezepte aus, die weniger als fünf Zutaten enthalten. */
/* Gerrit */
SELECT REZEPT.name, COUNT(*) as anzahl_zutaten 
    FROM REZEPT
    JOIN REZEPT_ZUTAT ON REZEPT_ZUTAT.rezept_id = REZEPT.rezept_id
    GROUP BY REZEPT.name
    HAVING COUNT(*) < 5;

/* Kombinierte Filter: Zeigt Rezepte an, die sowohl weniger als fünf Zutaten enthalten als auch eine bestimmte Ernährungskategorie erfüllen. */
/* Gerrit */
SELECT REZEPT.name, COUNT(*) as anzahl_zutaten 
    FROM REZEPT
    JOIN ERNAEHRUNGSKATEGORIE ON ERNAEHRUNGSKATEGORIE.kategorie_id = REZEPT.kategorie_id
    JOIN REZEPT_ZUTAT ON REZEPT_ZUTAT.rezept_id = REZEPT.rezept_id
    WHERE ERNAEHRUNGSKATEGORIE.bezeichnung IN ('$ERNAEHRUNGSKATEGORIE-BEZEICHNUNG')
    GROUP BY REZEPT.rezept_id
    HAVING COUNT(*) < 5;

/* Eigenständige Abfragen entwickeln: Erstellt mindestens drei weitere sinnvolle Abfragen, die den Rezept-Service erweitern oder optimieren. */

/* Verwendung komplexer SQL-Elemente: Stellt sicher, dass ihr alle der folgenden SQL-Elemente mindestens einmal verwendet: INNER JOIN, LEFT/RIGHT JOIN, Subselects, Aggregatfunktionen */
/* Gerrit: LEFT JOIN, Aggregatfunktionen (SUM, COUNT) */

/* Zugriffskonzept und DSGVO-konforme Datenverarbeitung implementieren: Verwendet Rollen, Views, Trigger und Stored Procedures. */

/* Stored Procedures */
/* NOTE: In PSQL müssen wir FUNCTIONs nutzen um Rückgabewerte zu bekommen */

/* Zutaten für ein Rezept abrufen (KUECHE) */
CREATE OR REPLACE FUNCTION GetZutatenFuerRezept(rezept_name VARCHAR)
RETURNS TABLE (
    name VARCHAR,
    zutat VARCHAR,
    menge NUMERIC,
    einheit VARCHAR
    )
    LANGUAGE plpgsql
    AS $$ 
    BEGIN
	RETURN QUERY
	SELECT r.name, z.bezeichnung, rz.menge, z.einheit
	FROM rezept r
	JOIN rezept_zutat rz ON r.rezept_id = rz.rezept_id
	JOIN zutat z ON rz.zutatennr = z.zutatennr
	WHERE r.name = rezept_name;
    END;
    $$;
/* Usage */
SELECT * FROM GetZutatenFuerRezept('Zucchini-Pfanne');

/* Neue Bestellung automatisch anlegen (VERKAUF) */
/*NOTE: funktioniert nur für valide kundennr */
CREATE OR REPLACE PROCEDURE CreateBestellungFuerKunde(kundennr INT)
    LANGUAGE plpgsql
    AS $$
    BEGIN
	INSERT INTO bestellung (kundennr, bestelldatum, rechnungsbetrag)
	VALUES (kundennr, CURRENT_DATE, 0);
    END;
    $$;
/* Usage */
CALL CreateBestellungFuerKunde(2001);

/* Rechungsbetrag automatisch aktualisieren nachdem Bestellungszutat hinzugefügt worden ist */
CREATE OR REPLACE FUNCTION update_bestellung_betrag()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE bestellung b
    SET rechnungsbetrag = (
        SELECT SUM(z.nettopreis * bz.menge)
        FROM bestellungzutat bz
        JOIN zutat z ON bz.zutatennr = z.zutatennr
        WHERE bz.bestellnr = b.bestellnr
    )
    WHERE b.bestellnr = NEW.bestellnr;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_update_bestellung_betrag
AFTER INSERT OR UPDATE ON bestellungzutat
FOR EACH ROW
EXECUTE FUNCTION update_bestellung_betrag();

/* Usage */
INSERT INTO BESTELLUNGZUTAT(BESTELLNR, ZUTATENNR, MENGE) VALUES (14, 1010, 10);

/* Views */
/* Rezepte mit Ernährungskategorie und Kalorien */
CREATE OR REPLACE VIEW v_rezepte_ernahrung_kalorien AS
SELECT 
    r.rezept_id,
    r.name AS rezept_name,
    ek.bezeichnung AS ernahrungskategorie,
    ROUND(SUM(z.kalorien * rz.menge / 100.0), 2) AS gesamt_kalorien
FROM rezept r
JOIN ernaehrungskategorie ek ON r.kategorie_id = ek.kategorie_id
JOIN rezept_zutat rz ON r.rezept_id = rz.rezept_id
JOIN zutat z ON rz.zutatennr = z.zutatennr
GROUP BY r.rezept_id, r.name, ek.bezeichnung
ORDER BY r.name;

/* Usage */
SELECT * FROM v_rezepte_ernahrung_kalorien;

/* DSGVO-konforme Kundenanzeige */
CREATE OR REPLACE VIEW v_kunde_dsgvo AS
SELECT 
    kundennr,
    CONCAT(LEFT(nachname, 1), '***') AS nachname_maskiert,
    CONCAT(LEFT(vorname, 1), '***') AS vorname_maskiert,
    EXTRACT(YEAR FROM geburtsdatum)::INT AS geburtsjahr,
    plz,
    ort
FROM kunde;

/* Usage */
SELECT * FROM v_kunde_dsgvo;

/* Trigger*/
/* Änderungen an Kundendaten protokollieren (DSGVO) */
CREATE TABLE kunde_audit (
    audit_id SERIAL PRIMARY KEY,
    kundennr INTEGER NOT NULL,
    nachname VARCHAR(50),
    vorname VARCHAR(50),
    geburtsdatum DATE,
    strasse VARCHAR(50),
    hausnr VARCHAR(6),
    plz VARCHAR(5),
    ort VARCHAR(50),
    telefon VARCHAR(25),
    email VARCHAR(50),
    geaendert_am TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    aktion TEXT NOT NULL -- 'UPDATE'
);

CREATE OR REPLACE FUNCTION trg_fnc_kunde_audit()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'UPDATE' THEN
        INSERT INTO kunde_audit (
            kundennr, nachname, vorname, geburtsdatum,
            strasse, hausnr, plz, ort, telefon, email, aktion
        )
        VALUES (
            OLD.kundennr, OLD.nachname, OLD.vorname, OLD.geburtsdatum,
            OLD.strasse, OLD.hausnr, OLD.plz, OLD.ort, OLD.telefon, OLD.email,
            TG_OP
        );
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_kunde_audit
AFTER UPDATE ON kunde
FOR EACH ROW
EXECUTE FUNCTION trg_fnc_kunde_audit();

/* Usage */
UPDATE kunde SET strasse = 'Neue Straße' WHERE kundennr = 2001;

/* Kundenanonymisierung bei Löschmarkierung (DSGVO) */
ALTER TABLE kunde
ADD COLUMN geloescht BOOLEAN DEFAULT FALSE;

CREATE OR REPLACE FUNCTION trg_fnc_kunde_anonymisieren()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.geloescht = TRUE AND OLD.geloescht = FALSE THEN
        UPDATE kunde
        SET nachname = 'ANONYM',
            vorname = 'ANONYM',
            geburtsdatum = NULL,
            strasse = NULL,
            hausnr = NULL,
            plz = NULL,
            ort = NULL,
            telefon = NULL,
            email = CONCAT('anon', kundennr, '@example.com')
        WHERE kundennr = NEW.kundennr;
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_kunde_anonymisieren
AFTER UPDATE OF geloescht ON kunde
FOR EACH ROW
EXECUTE FUNCTION trg_fnc_kunde_anonymisieren();

/* Usage */
UPDATE kunde SET geloescht = TRUE WHERE kundennr = 2001;

/* Rollen: 
 1. KUECHE: Zugriff auf Rezepte und Zutaten.
 2. VERKAUF: Zugriff auf Kunden und Bestellungen.
 3. EINKAUF: Zugriff auf Lieferanten und Zutatenpreise.
 4. ADMIN(IT): Zugriff auf das gesamte Datenbanksystem.
*/

/*Umsetzung*/
CREATE ROLE KUECHE NOINHERIT;
CREATE ROLE VERKAUF NOINHERIT;
CREATE ROLE EINKAUF NOINHERIT;
CREATE ROLE ADMIN NOINHERIT;

REVOKE ALL ON 
    KUNDE, ZUTAT, LIEFERANT, BESTELLUNG, BESTELLUNGZUTAT,
    ERNAEHRUNGSKATEGORIE, REZEPT, REZEPT_ZUTAT 
FROM PUBLIC;

/*Rollen Verkauf*/
GRANT SELECT, INSERT, UPDATE ON KUNDE TO VERKAUF;
GRANT SELECT, INSERT, UPDATE ON BESTELLUNG TO VERKAUF;
GRANT SELECT ON BESTELLUNGZUTAT TO VERKAUF;

GRANT SELECT ON ERNAEHRUNGSKATEGORIE TO VERKAUF;
GRANT SELECT ON REZEPT TO VERKAUF;
GRANT SELECT ON REZEPT_ZUTAT TO VERKAUF;


/*Rollen Einkauf*/
GRANT SELECT, INSERT, UPDATE ON ZUTAT TO EINKAUF;
GRANT SELECT, INSERT, UPDATE ON LIEFERANT TO EINKAUF;

GRANT SELECT ON ERNAEHRUNGSKATEGORIE TO EINKAUF;
GRANT SELECT ON REZEPT TO EINKAUF;
GRANT SELECT ON REZEPT_ZUTAT TO EINKAUF;

/*Rollen K�che*/
GRANT SELECT ON ZUTAT TO KUECHE;

GRANT SELECT ON ERNAEHRUNGSKATEGORIE TO KUECHE;
GRANT SELECT, INSERT, UPDATE, DELETE ON REZEPT TO KUECHE;
GRANT SELECT, INSERT, UPDATE, DELETE ON REZEPT_ZUTAT TO KUECHE;

/*Rollen Admin*/
GRANT ALL PRIVILEGES ON KUNDE TO ADMIN;
GRANT ALL PRIVILEGES ON ZUTAT TO ADMIN;
GRANT ALL PRIVILEGES ON BESTELLUNG TO ADMIN;
GRANT ALL PRIVILEGES ON BESTELLUNGZUTAT TO ADMIN;
GRANT ALL PRIVILEGES ON LIEFERANT TO ADMIN;

GRANT ALL PRIVILEGES ON ERNAEHRUNGSKATEGORIE TO ADMIN;
GRANT ALL PRIVILEGES ON REZEPT TO ADMIN;
GRANT ALL PRIVILEGES ON REZEPT_ZUTAT TO ADMIN;

