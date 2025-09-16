IF DB_ID('MovieRentalDB') IS NULL
  CREATE DATABASE MovieRentalDB;
GO
USE MovieRentalDB;
GO

IF OBJECT_ID('dbo.Payments','U') IS NOT NULL DROP TABLE dbo.Payments;
IF OBJECT_ID('dbo.Rentals','U')  IS NOT NULL DROP TABLE dbo.Rentals;
IF OBJECT_ID('dbo.Inventory','U') IS NOT NULL DROP TABLE dbo.Inventory;
IF OBJECT_ID('dbo.MovieGenres','U') IS NOT NULL DROP TABLE dbo.MovieGenres;
IF OBJECT_ID('dbo.Genres','U')   IS NOT NULL DROP TABLE dbo.Genres;
IF OBJECT_ID('dbo.Movies','U')   IS NOT NULL DROP TABLE dbo.Movies;
IF OBJECT_ID('dbo.Customers','U')IS NOT NULL DROP TABLE dbo.Customers;
IF OBJECT_ID('dbo.Staff','U')    IS NOT NULL DROP TABLE dbo.Staff;
IF OBJECT_ID('dbo.Stores','U')   IS NOT NULL DROP TABLE dbo.Stores;
GO

CREATE TABLE dbo.Customers (
  CustomerID       INT IDENTITY(1,1) PRIMARY KEY,
  FirstName        NVARCHAR(50) NOT NULL,
  LastName         NVARCHAR(50) NOT NULL,
  Email            NVARCHAR(255) UNIQUE NOT NULL,
  Phone            NVARCHAR(25) NULL,
  CreatedAt        DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
  Status           NVARCHAR(20) NOT NULL DEFAULT 'active'
);

CREATE TABLE dbo.Movies (
  MovieID          INT IDENTITY(1,1) PRIMARY KEY,
  Title            NVARCHAR(200) NOT NULL,
  ReleaseYear      INT NULL,
  Rating           NVARCHAR(10) NULL,
  RentalRate       DECIMAL(6,2) NOT NULL,
  ReplacementCost  DECIMAL(8,2) NOT NULL,
  CreatedAt        DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME()
);

CREATE TABLE dbo.Genres (
  GenreID          INT IDENTITY(1,1) PRIMARY KEY,
  Name             NVARCHAR(50) UNIQUE NOT NULL
);

CREATE TABLE dbo.MovieGenres (
  MovieID          INT NOT NULL FOREIGN KEY REFERENCES dbo.Movies(MovieID),
  GenreID          INT NOT NULL FOREIGN KEY REFERENCES dbo.Genres(GenreID),
  CONSTRAINT PK_MovieGenres PRIMARY KEY (MovieID, GenreID)
);

CREATE TABLE dbo.Stores (
  StoreID          INT IDENTITY(1,1) PRIMARY KEY,
  Name             NVARCHAR(100) NOT NULL,
  AddressLine1     NVARCHAR(120) NULL,
  City             NVARCHAR(60) NULL,
  State            NVARCHAR(30) NULL
);

CREATE TABLE dbo.Staff (
  StaffID          INT IDENTITY(1,1) PRIMARY KEY,
  StoreID          INT NOT NULL FOREIGN KEY REFERENCES dbo.Stores(StoreID),
  FirstName        NVARCHAR(50) NOT NULL,
  LastName         NVARCHAR(50) NOT NULL,
  Email            NVARCHAR(255) UNIQUE NOT NULL,
  Active           BIT NOT NULL DEFAULT 1
);

CREATE TABLE dbo.Inventory (
  InventoryID      INT IDENTITY(1,1) PRIMARY KEY,
  MovieID          INT NOT NULL FOREIGN KEY REFERENCES dbo.Movies(MovieID),
  StoreID          INT NOT NULL FOREIGN KEY REFERENCES dbo.Stores(StoreID),
  CopiesTotal      INT NOT NULL CHECK (CopiesTotal >= 0),
  CopiesAvailable  INT NOT NULL CHECK (CopiesAvailable >= 0)
);

CREATE TABLE dbo.Rentals (
  RentalID         INT IDENTITY(1,1) PRIMARY KEY,
  InventoryID      INT NOT NULL FOREIGN KEY REFERENCES dbo.Inventory(InventoryID),
  CustomerID       INT NOT NULL FOREIGN KEY REFERENCES dbo.Customers(CustomerID),
  StaffID          INT NOT NULL FOREIGN KEY REFERENCES dbo.Staff(StaffID),
  RentedAt         DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
  DueAt            DATETIME2(0) NOT NULL,
  ReturnedAt       DATETIME2(0) NULL,
  Status           NVARCHAR(20) NOT NULL DEFAULT 'out'
);

CREATE TABLE dbo.Payments (
  PaymentID        INT IDENTITY(1,1) PRIMARY KEY,
  RentalID         INT NOT NULL FOREIGN KEY REFERENCES dbo.Rentals(RentalID),
  Amount           DECIMAL(8,2) NOT NULL CHECK (Amount >= 0),
  PaidAt           DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
  Method           NVARCHAR(20) NOT NULL DEFAULT 'card'
);
GO
