USE MovieRentalDB;
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_Rentals_Customer_Returned' AND object_id=OBJECT_ID('dbo.Rentals'))
  CREATE NONCLUSTERED INDEX IX_Rentals_Customer_Returned ON dbo.Rentals(CustomerID, ReturnedAt) INCLUDE (DueAt, InventoryID);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_Inventory_Store_Movie' AND object_id=OBJECT_ID('dbo.Inventory'))
  CREATE NONCLUSTERED INDEX IX_Inventory_Store_Movie ON dbo.Inventory(StoreID, MovieID) INCLUDE (CopiesAvailable);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_Movies_Title' AND object_id=OBJECT_ID('dbo.Movies'))
  CREATE NONCLUSTERED INDEX IX_Movies_Title ON dbo.Movies(Title);
GO
