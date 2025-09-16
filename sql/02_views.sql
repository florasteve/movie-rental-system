USE MovieRentalDB;
GO

IF OBJECT_ID('dbo.vwCurrentRentals','V') IS NOT NULL DROP VIEW dbo.vwCurrentRentals;
GO
CREATE VIEW dbo.vwCurrentRentals AS
SELECT r.RentalID, r.InventoryID, r.CustomerID, r.StaffID,
       r.RentedAt, r.DueAt, r.ReturnedAt, r.Status,
       i.StoreID, i.MovieID, m.Title
FROM dbo.Rentals r
JOIN dbo.Inventory i ON r.InventoryID = i.InventoryID
JOIN dbo.Movies m    ON i.MovieID = m.MovieID
WHERE r.ReturnedAt IS NULL;
GO
