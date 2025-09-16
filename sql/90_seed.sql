USE MovieRentalDB;
GO

INSERT dbo.Stores (Name, AddressLine1, City, State)
VALUES ('Downtown Video', '123 Main St', 'Boone', 'NC');

INSERT dbo.Staff (StoreID, FirstName, LastName, Email)
SELECT StoreID, 'Sam','Clerk','sam.clerk@store.local' FROM dbo.Stores;

INSERT dbo.Customers (FirstName, LastName, Email, Phone)
VALUES ('Alex','Johnson','alex.j@example.com','555-1111'),
       ('Taylor','Nguyen','taylor.n@example.com','555-2222');

INSERT dbo.Genres (Name) VALUES ('Action'),('Comedy'),('Drama');

INSERT dbo.Movies (Title, ReleaseYear, Rating, RentalRate, ReplacementCost)
VALUES ('The Matrix', 1999, 'R', 3.99, 19.99),
       ('The Office: The Movie', 2012, 'PG-13', 2.99, 14.99);

INSERT dbo.MovieGenres (MovieID, GenreID)
SELECT m.MovieID, g.GenreID
FROM dbo.Movies m
JOIN dbo.Genres g ON (m.Title='The Matrix' AND g.Name='Action')
UNION ALL
SELECT m.MovieID, g.GenreID
FROM dbo.Movies m
JOIN dbo.Genres g ON (m.Title='The Office: The Movie' AND g.Name='Comedy');

INSERT dbo.Inventory (MovieID, StoreID, CopiesTotal, CopiesAvailable)
SELECT (SELECT MovieID FROM dbo.Movies WHERE Title='The Matrix'),
       (SELECT TOP 1 StoreID FROM dbo.Stores), 5, 5
UNION ALL
SELECT (SELECT MovieID FROM dbo.Movies WHERE Title='The Office: The Movie'),
       (SELECT TOP 1 StoreID FROM dbo.Stores), 3, 3;
GO
