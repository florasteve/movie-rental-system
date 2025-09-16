USE MovieRentalDB;
GO

IF OBJECT_ID('dbo.tr_Rentals_LateStatus','TR') IS NOT NULL DROP TRIGGER dbo.tr_Rentals_LateStatus;
GO
CREATE TRIGGER dbo.tr_Rentals_LateStatus
ON dbo.Rentals
AFTER INSERT, UPDATE
AS
BEGIN
  SET NOCOUNT ON;
  UPDATE r
    SET Status = CASE
                   WHEN r.ReturnedAt IS NULL AND r.DueAt < SYSUTCDATETIME() THEN 'late'
                   WHEN r.ReturnedAt IS NULL THEN 'out'
                   ELSE 'returned'
                 END
  FROM dbo.Rentals r
  JOIN inserted i ON r.RentalID = i.RentalID;
END
GO
