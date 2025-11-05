/* setting up functions, procedures and views */

/* Zutaten fuer ein Rezept abrufen (KUECHE) */
CREATE OR REPLACE FUNCTION get_zutaten_fuer_rezept(rezept_name VARCHAR)
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

/* Neue Bestellung automatisch anlegen (VERKAUF) */
/*NOTE: funktioniert nur fuer valide kundennr */
CREATE OR REPLACE PROCEDURE create_bestellung_fuer_kunde(kundennr INT)
    LANGUAGE plpgsql
    AS $$
    BEGIN
	INSERT INTO bestellung (kundennr, bestelldatum, rechnungsbetrag)
	VALUES (kundennr, CURRENT_DATE, 0);
    END;
    $$;

/* Rechungsbetrag automatisch aktualisieren nachdem Bestellungszutat hinzugefÃ¼gt worden ist */
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

/* Views */
/* Rezepte mit Ernaehrungskategorie und Kalorien */
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

/* Trigger*/
/* Aenderungen an Kundendaten protokollieren (DSGVO) */
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

/* Rollen: 
 1. KUECHE: Zugriff auf Rezepte und Zutaten.
 2. VERKAUF: Zugriff auf Kunden und Bestellungen.
 3. EINKAUF: Zugriff auf Lieferanten und Zutatenpreise.
 4. ADMIN(IT): Zugriff auf das gesamte Datenbanksystem.
*/

CREATE ROLE KUECHE NOINHERIT;
CREATE ROLE VERKAUF NOINHERIT;
CREATE ROLE EINKAUF NOINHERIT;
/*NOTE: admin exists per default
CREATE ROLE ADMIN NOINHERIT; */

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

/*Rollen Küche*/
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


/* Usage examples of functions, procedures and views:
SELECT * FROM get_zutaten_fuer_rezept('Zucchini-Pfanne');
CALL create_bestellung_fuer_kunde(2001);
SELECT * FROM v_rezepte_ernahrung_kalorien;
SELECT * FROM v_kunde_dsgvo;
UPDATE kunde SET strasse = 'Neue Strasse' WHERE kundennr = 2001;
INSERT INTO BESTELLUNGZUTAT(BESTELLNR, ZUTATENNR, MENGE) VALUES (14, 1010, 10);
UPDATE kunde SET geloescht = TRUE WHERE kundennr = 2001;
*/
