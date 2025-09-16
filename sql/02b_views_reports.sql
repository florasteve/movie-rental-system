USE MovieRentalDB;
GO

IF OBJECT_ID('dbo.vwOverdueRentals','V') IS NOT NULL DROP VIEW dbo.vwOverdueRentals;
GO
CREATE VIEW dbo.vwOverdueRentals AS
SELECT r.RentalID, r.CustomerID, r.InventoryID, r.DueAt, r.ReturnedAt,
       DATEDIFF(DAY, r.DueAt, COALESCE(r.ReturnedAt, SYSUTCDATETIME())) AS DaysLate,
       CASE WHEN r.ReturnedAt IS NULL THEN 'out' ELSE 'returned' END AS ReturnState
FROM dbo.Rentals r
WHERE (r.ReturnedAt IS NULL AND r.DueAt < SYSUTCDATETIME())
   OR (r.ReturnedAt IS NOT NULL AND r.ReturnedAt > r.DueAt);
GO

IF OBJECT_ID('dbo.vwLowInventory','V') IS NOT NULL DROP VIEW dbo.vwLowInventory;
GO
CREATE VIEW dbo.vwLowInventory AS
SELECT i.InventoryID, i.StoreID, i.MovieID, i.CopiesTotal, i.CopiesAvailable, m.Title
FROM dbo.Inventory i
JOIN dbo.Movies m ON m.MovieID = i.MovieID
WHERE i.CopiesAvailable <= 1;
GO
