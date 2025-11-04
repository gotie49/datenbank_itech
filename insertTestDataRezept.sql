SET ROLE ADMIN;
INSERT INTO ERNAEHRUNGSKATEGORIE (BEZEICHNUNG, BESCHREIBUNG) VALUES ('Vegetarisch', 'Rezepte ohne Fleisch'), 
('Vegan', 'Rezepte ohne tierische Produkte'), ('Fleischgerichte', 'Rezepte mit Fleisch'), 
('Frühstück', 'Rezepte für das Frühstück'), ('Desserts', 'Süße Rezepte zum Abschluss');

INSERT INTO REZEPT (NAME, BESCHREIBUNG, KATEGORIE_ID, ERSTELLUNGSDATUM) VALUES
('Zucchini-Pfanne', 'Leckere Pfanne mit Zucchini und Karotten', 1, '2025-10-01'),
('Tomaten-Rucola-Salat', 'Frischer Salat mit Tomaten, Rucola und Basilikum', 2, '2025-10-02'),
('Kartoffelgratin', 'Cremiges Kartoffelgratin mit Butter und Milch', 3, '2025-10-03'),
('Rührei mit Kräutern', 'Rührei mit Schnittlauch und Schalotten', 4, '2025-10-04'),
('Tofu-Würstchen mit Couscous', 'Vegane Würstchen mit Couscous und Gemüsebrühe', 2, '2025-10-05');

INSERT INTO REZEPT_ZUTAT (REZEPT_ID, ZUTATENNR, MENGE, EINHEIT) VALUES
(1, 1001, 2, 'Stück'),
(1, 1005, 3, 'Stück'),
(1, 1006, 2, 'Stück'), 
(1, 7043, 1, 'Würfel'),
(2, 1003, 4, 'Stück'),
(2, 1007, 1, 'Bund'),
(2, 1010, 1, 'Bund'),
(3, 1006, 5, 'Stück'),
(3, 3003, 50, 'Stück'),
(3, 3001, 2, 'Liter'),
(4, 4001, 4, 'Stück'),
(4, 1004, 2, 'Stück'),
(4, 1012, 1, 'Bund'),
(5, 9001, 3, 'Stück'),
(5, 6408, 2, 'Packung'),
(5, 7043, 2, 'Würfel'),
(5, 6300, 1, 'Dose');  
RESET ROLE;