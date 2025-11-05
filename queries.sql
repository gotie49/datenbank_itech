/*Fachliche Anforderungen an die SQL-Statements */

/* Zutaten eines Rezepts abrufen: Stellt eine Abfrage bereit, mit der alle Zutaten eines ausgewählten Rezepts sowie den jeweiligen Mengenangaben angezeigt werden. */
SELECT REZEPT.name, ZUTAT.bezeichnung, REZEPT_ZUTAT.menge 
    FROM REZEPT_ZUTAT 
    JOIN REZEPT ON REZEPT.rezept_id = REZEPT_ZUTAT.rezept_id
    JOIN ZUTAT ON ZUTAT.zutatennr = REZEPT_ZUTAT.zutatennr
    WHERE REZEPT.name IN ('$REZEPT-NAME');

/* Rezepte mit bestimmter Zutat finden: Zeigt alle Rezepte an, die eine ausgewählte Zutat enthalten. */
SELECT REZEPT.name, REZEPT.beschreibung, ZUTAT.bezeichnung, REZEPT_ZUTAT.menge 
    FROM REZEPT 
    JOIN REZEPT_ZUTAT ON REZEPT.rezept_id = REZEPT_ZUTAT.rezept_id
    JOIN ZUTAT ON REZEPT_ZUTAT.zutatennr = ZUTAT.zutatennr
    WHERE ZUTAT.bezeichnung IN ('$ZUTAT-BEZEICHNUNG');

/* Anzahl Rezepte nach Ernaehrungskategorie: Entwickelt eine Abfrage, die anzeigt wie viele Rezepte pro Ernährungskategorie (z.B. vegan, vegetarisch) vorhanden sind. */
SELECT ERNAEHRUNGSKATEGORIE.bezeichnung, COUNT(*) as anzahl_rezepte
    FROM REZEPT 
    JOIN ERNAEHRUNGSKATEGORIE ON REZEPT.kategorie_id = ERNAEHRUNGSKATEGORIE.kategorie_id
    GROUP BY ERNAEHRUNGSKATEGORIE.bezeichnung;

/* Durchschnittliche Naehrwerte berechnen: Berechnet die durchschnittlichen Naehrwerte (Kalorien, Proteine, Kohlenhydrate, Fett etc.) pro Bestellung für alle Bestellungen eines Kunden. */
SELECT BESTELLUNG.bestellnr, 
    SUM(ZUTAT.kalorien * BESTELLUNGZUTAT.menge) as kalorien, 
    SUM(ZUTAT.kohlenhydrate * BESTELLUNGZUTAT.menge) as kohlenhydrate, 
    SUM(ZUTAT.protein * BESTELLUNGZUTAT.menge) as protein 
FROM BESTELLUNG
    JOIN BESTELLUNGZUTAT ON BESTELLUNG.bestellnr = BESTELLUNGZUTAT.bestellnr
    JOIN ZUTAT ON BESTELLUNGZUTAT.zutatennr = ZUTAT.zutatennr
    WHERE BESTELLUNG.kundennr IN ('$BESTELLUNG-KUNDENNR')
    GROUP BY BESTELLUNG.bestellnr;

/* Unverknuepfte Zutaten identifizieren: Findet alle Zutaten, die bisher keinem Rezept zugeordnet sind. */
SELECT ZUTAT.zutatennr, ZUTAT.bezeichnung 
    FROM ZUTAT
    LEFT JOIN REZEPT_ZUTAT ON REZEPT_ZUTAT.zutatennr = ZUTAT.zutatennr
    WHERE REZEPT_ZUTAT.zutatennr IS NULL;

/* Rezepte nach Kalorienmenge filtern: Stellt alle Rezepte zusammen, die eine bestimmte maximale Kalorienmenge nicht ueberschreiten. */
SELECT REZEPT.rezept_id, SUM(ZUTAT.kalorien * REZEPT_ZUTAT.menge) AS rezept_kalorien 
    FROM REZEPT
    JOIN REZEPT_ZUTAT ON REZEPT_ZUTAT.rezept_id  = REZEPT.rezept_id
    JOIN ZUTAT ON ZUTAT.zutatennr = REZEPT_ZUTAT.zutatennr
    GROUP BY REZEPT.rezept_id
    HAVING SUM(ZUTAT.kalorien * REZEPT_ZUTAT.menge) < $KALORIENMENGE;

/* Rezepte mit wenigen Zutaten finden: Wählt alle Rezepte aus, die weniger als fuenf Zutaten enthalten. */
SELECT REZEPT.name, COUNT(*) as anzahl_zutaten 
    FROM REZEPT
    JOIN REZEPT_ZUTAT ON REZEPT_ZUTAT.rezept_id = REZEPT.rezept_id
    GROUP BY REZEPT.name
    HAVING COUNT(*) < 5;

/* Kombinierte Filter: Zeigt Rezepte an, die sowohl weniger als fuenf Zutaten enthalten als auch eine bestimmte Ernaehrungskategorie erfaellen. */
SELECT REZEPT.name, COUNT(*) as anzahl_zutaten 
    FROM REZEPT
    JOIN ERNAEHRUNGSKATEGORIE ON ERNAEHRUNGSKATEGORIE.kategorie_id = REZEPT.kategorie_id
    JOIN REZEPT_ZUTAT ON REZEPT_ZUTAT.rezept_id = REZEPT.rezept_id
    WHERE ERNAEHRUNGSKATEGORIE.bezeichnung IN ('$ERNAEHRUNGSKATEGORIE-BEZEICHNUNG')
    GROUP BY REZEPT.rezept_id
    HAVING COUNT(*) < 5;

/* Eigenstaendige Abfragen entwickeln: Erstellt mindestens drei weitere sinnvolle Abfragen, die den Rezept-Service erweitern oder optimieren. */

/* Verwendung komplexer SQL-Elemente: Stellt sicher, dass ihr alle der folgenden SQL-Elemente mindestens einmal verwendet: INNER JOIN, LEFT/RIGHT JOIN, Subselects, Aggregatfunktionen */
/* Gerrit: LEFT JOIN, Aggregatfunktionen (SUM, COUNT) */

/* Zugriffskonzept und DSGVO-konforme Datenverarbeitung implementieren: Verwendet Rollen, Views, Trigger und Stored Procedures. */

