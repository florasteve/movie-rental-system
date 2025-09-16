USE MovieRentalDB;
GO
IF OBJECT_ID('dbo.ReturnMovie','P') IS NOT NULL DROP PROCEDURE dbo.ReturnMovie;
GO
CREATE PROCEDURE dbo.ReturnMovie
  @RentalID INT
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @InventoryID INT, @DueAt DATETIME2(0), @ReturnedAt DATETIME2(0)=SYSUTCDATETIME();

  SELECT @InventoryID = InventoryID, @DueAt = DueAt
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

  DECLARE @fee DECIMAL(8,2) =
    CASE WHEN @ReturnedAt > @DueAt
         THEN CAST(DATEDIFF(DAY, @DueAt, @ReturnedAt) AS DECIMAL(8,2)) * 1.50
         ELSE 0 END;

  IF @fee > 0
    INSERT dbo.Payments (RentalID, Amount, Method) VALUES (@RentalID, @fee, 'card');
END
GO
