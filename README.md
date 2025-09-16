# 🎬 Movie Rental System

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE) [![SQL Server](https://img.shields.io/badge/DB-Microsoft%20SQL%20Server-blue)](https://www.microsoft.com/sql-server) [![Docker](https://img.shields.io/badge/Container-Docker-informational)](https://www.docker.com/)

A Dockerized Microsoft SQL Server database for a classic movie rental domain—customers, movies, inventory, rentals, and payments—with seed data, views, procs, and triggers.

## 🗺️ ER Diagram (Mermaid)
```mermaid
erDiagram
  CUSTOMERS ||--o{ RENTALS : makes
  STAFF ||--o{ RENTALS : handles
  STORES ||--o{ STAFF : employs
  STORES ||--o{ INVENTORY : stocks
  MOVIES ||--o{ INVENTORY : listed_as
  MOVIES ||--o{ MOVIEGENRES : labeled
  GENRES ||--o{ MOVIEGENRES : categorizes
  INVENTORY ||--o{ RENTALS : fulfills
  RENTALS ||--o{ PAYMENTS : billed

  CUSTOMERS { int CustomerID PK string FirstName string LastName string Email string Phone string Status }
  MOVIES { int MovieID PK string Title int ReleaseYear string Rating decimal RentalRate decimal ReplacementCost }
  GENRES { int GenreID PK string Name }
  MOVIEGENRES { int MovieID FK int GenreID FK }
  STORES { int StoreID PK string Name string AddressLine1 string City string State }
  STAFF { int StaffID PK int StoreID FK string FirstName string LastName string Email bool Active }
  INVENTORY { int InventoryID PK int MovieID FK int StoreID FK int CopiesTotal int CopiesAvailable }
  RENTALS { int RentalID PK int InventoryID FK int CustomerID FK int StaffID FK datetime RentedAt datetime DueAt datetime ReturnedAt string Status }
  PAYMENTS { int PaymentID PK int RentalID FK decimal Amount datetime PaidAt string Method }
```

## 🚀 Quick start  
1. Create .env with `SA_PASSWORD`
1. `docker compose -f docker/docker-compose.yml up -d`
1. Apply scripts: `sqlcmd -i scripts/apply.sql` via container (see scripts section)
1. Try `RentMovie` / `ReturnMovie` to validate logic.

## 📂 Structure  
- `docker/` compose & runtime  
- `sql/` DDL, views, procs, triggers, seed  
- `scripts/` orchestration `.sql`  
- `data/` CSVs (future)

## 🔧 Scripts  
Use `scripts/apply.sql` to apply in correct order.

## 📝 License  
MIT — see LICENSE.
