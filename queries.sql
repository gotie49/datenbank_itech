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

/* Neue Bestellung automatisch anlegen (VERKAUF)*/

/* Views */
/* Rezepte mit Ernährungskategorie und Kalorien */
/* DSGVO-konforme Kundenanzeige */

/* Trigger*/
/* Änderungen an Kundendaten protokollieren(DSGVO) */
/* Kundenanonymisierung bei Löschmarkierung(DSGVO) */

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

