# Movie Rental System

Relational database for **movie rental operations**: catalog, inventory, customers, and rentals.  
Built for **SQL Server** in **SSMS** with a normalized schema, **T-SQL** stored procedures (rent/return), and reporting views.

---

## ✨ Features
- Movie catalog with inventory counts (`CopiesTotal`, `CopiesAvailable`)
- Customer registry with membership status
- Rental workflow: **Rent → Return** with due dates and optional late fees
- Views for **overdues**, **top movies**, and **current availability**
- Sample queries for utilization and customer activity

---

## 🧱 Schema (Core Tables)

- `Movies(MovieID, Title, ReleaseYear, Rating, Genre, CopiesTotal, CopiesAvailable, CreatedAt, UpdatedAt)`
- `Customers(CustomerID, FirstName, LastName, Email, MemberSince, Status, CreatedAt, UpdatedAt)`
- `Rentals(RentalID, MovieID, CustomerID, RentalDate, DueDate, ReturnDate, FeeAccrued, CreatedAt, UpdatedAt)`

> Optional status semantics: `Customers.Status = Active | Inactive`

---

## 🗺️ ER Diagram (Mermaid)

```mermaid
erDiagram
  MOVIES   ||--o{ RENTALS : loaned
  CUSTOMERS||--o{ RENTALS : borrows

  MOVIES {
    int MovieID PK
    string Title
    int ReleaseYear
    string Rating
    string Genre
    int CopiesTotal
    int CopiesAvailable
  }

  CUSTOMERS {
    int CustomerID PK
    string FirstName
    string LastName
    string Email
    date MemberSince
    string Status
  }

  RENTALS {
    int RentalID PK
    int MovieID FK
    int CustomerID FK
    date RentalDate
    date DueDate
    date ReturnDate
    decimal FeeAccrued
  }
