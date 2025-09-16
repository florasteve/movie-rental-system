USE MovieRentalDB;
GO

-- Allow explicit identity inserts for deterministic seeds.
SET IDENTITY_INSERT dbo.Stores ON;
BULK INSERT dbo.Stores
  FROM '/var/opt/mssql/data/stores.csv'
  WITH (FIRSTROW=2, FIELDTERMINATOR=',', ROWTERMINATOR='\n', KEEPIDENTITY);
SET IDENTITY_INSERT dbo.Stores OFF;

SET IDENTITY_INSERT dbo.Staff ON;
BULK INSERT dbo.Staff
  FROM '/var/opt/mssql/data/staff.csv'
  WITH (FIRSTROW=2, FIELDTERMINATOR=',', ROWTERMINATOR='\n', KEEPIDENTITY);
SET IDENTITY_INSERT dbo.Staff OFF;

SET IDENTITY_INSERT dbo.Customers ON;
BULK INSERT dbo.Customers
  FROM '/var/opt/mssql/data/customers.csv'
  WITH (FIRSTROW=2, FIELDTERMINATOR=',', ROWTERMINATOR='\n', KEEPIDENTITY);
SET IDENTITY_INSERT dbo.Customers OFF;

SET IDENTITY_INSERT dbo.Movies ON;
BULK INSERT dbo.Movies
  FROM '/var/opt/mssql/data/movies.csv'
  WITH (FIRSTROW=2, FIELDTERMINATOR=',', ROWTERMINATOR='\n', KEEPIDENTITY);
SET IDENTITY_INSERT dbo.Movies OFF;

SET IDENTITY_INSERT dbo.Genres ON;
BULK INSERT dbo.Genres
  FROM '/var/opt/mssql/data/genres.csv'
  WITH (FIRSTROW=2, FIELDTERMINATOR=',', ROWTERMINATOR='\n', KEEPIDENTITY);
SET IDENTITY_INSERT dbo.Genres OFF;

BULK INSERT dbo.MovieGenres
  FROM '/var/opt/mssql/data/movie_genres.csv'
  WITH (FIRSTROW=2, FIELDTERMINATOR=',', ROWTERMINATOR='\n');

SET IDENTITY_INSERT dbo.Inventory ON;
BULK INSERT dbo.Inventory
  FROM '/var/opt/mssql/data/inventory.csv'
  WITH (FIRSTROW=2, FIELDTERMINATOR=',', ROWTERMINATOR='\n', KEEPIDENTITY);
SET IDENTITY_INSERT dbo.Inventory OFF;
GO
