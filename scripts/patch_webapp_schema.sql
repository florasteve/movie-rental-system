IF DB_ID('MovieRentalDB') IS NULL CREATE DATABASE MovieRentalDB;
GO
USE MovieRentalDB;
GO

-- Ensure Rentals exists and has ReturnDate
IF OBJECT_ID('dbo.Rentals', 'U') IS NULL
BEGIN
  CREATE TABLE dbo.Rentals (
    RentalId   INT IDENTITY(1,1) PRIMARY KEY,
    InventoryId INT NOT NULL,
    CustomerId  INT NOT NULL,
    RentalDate  DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    ReturnDate  DATETIME2 NULL
  );
END
ELSE
BEGIN
  IF COL_LENGTH('dbo.Rentals','ReturnDate') IS NULL
    ALTER TABLE dbo.Rentals ADD ReturnDate DATETIME2 NULL;
END
GO

-- Match the error you saw (50002) and update ReturnDate on return
CREATE OR ALTER PROCEDURE dbo.ReturnMovie
  @RentalId INT
AS
BEGIN
  SET NOCOUNT ON;

  IF NOT EXISTS (
    SELECT 1 FROM dbo.Rentals
    WHERE RentalId = @RentalId AND ReturnDate IS NULL
  )
  BEGIN
    ;THROW 50002, 'Rental not found or already returned.', 1;
  END

  UPDATE dbo.Rentals
  SET ReturnDate = SYSUTCDATETIME()
  WHERE RentalId = @RentalId AND ReturnDate IS NULL;
END
GO
