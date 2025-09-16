USE MovieRentalDB;
GO

IF OBJECT_ID('dbo.RentMovie','P') IS NOT NULL DROP PROCEDURE dbo.RentMovie;
GO
CREATE PROCEDURE dbo.RentMovie
  @InventoryID INT,
  @CustomerID  INT,
  @StaffID     INT,
  @Days        INT = 3
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @available INT;
  SELECT @available = CopiesAvailable FROM dbo.Inventory WITH (UPDLOCK, ROWLOCK) WHERE InventoryID = @InventoryID;

  IF @available IS NULL OR @available < 1
    THROW 50001, 'No copies available for this inventory item.', 1;

  UPDATE dbo.Inventory
    SET CopiesAvailable = CopiesAvailable - 1
    WHERE InventoryID = @InventoryID;

  INSERT dbo.Rentals (InventoryID, CustomerID, StaffID, DueAt)
  VALUES (@InventoryID, @CustomerID, @StaffID, DATEADD(DAY, @Days, SYSUTCDATETIME()));
END
GO

IF OBJECT_ID('dbo.ReturnMovie','P') IS NOT NULL DROP PROCEDURE dbo.ReturnMovie;
GO
CREATE PROCEDURE dbo.ReturnMovie
  @RentalID INT
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @InventoryID INT, @ReturnedAt DATETIME2(0) = SYSUTCDATETIME();

  SELECT @InventoryID = InventoryID
  FROM dbo.Rentals WITH (UPDLOCK, ROWLOCK)
  WHERE RentalID = @RentalID AND ReturnedAt IS NULL;

  IF @InventoryID IS NULL
    THROW 50002, 'Rental not found or already returned.', 1;

  UPDATE dbo.Rentals
    SET ReturnedAt = @ReturnedAt, Status = 'returned'
    WHERE RentalID = @RentalID;

  UPDATE dbo.Inventory
    SET CopiesAvailable = CopiesAvailable + 1
    WHERE InventoryID = @InventoryID;
END
GO
