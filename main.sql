-- 1-st task --
create database SportsShop;
go;

use SportsShop;
go;

create table Products
(
    ProductID int identity(1, 1) not null primary key,
    ProductName nvarchar(20) not null,
    ProductType nvarchar(20) not null,
    ProductAvailable int not null check(ProductAvailable >= 0) default 0,
    ProductCost money not null check(ProductCost >= 0) default 0,
    ProductSellingPrice money not null check(ProductSellingPrice >= 0 and ProductSellingPrice >= ProductCost) default ProductCost,
    ProductProducer nvarchar(20) not null
);
go;

create table Employees
(
    EmployeeID int identity(1, 1) not null primary key,
    EmployeeSNP nvarchar(40) not null,
    EmployeePosition nvarchar(20) not null,
    EmployeeEmploymentDate date not null default getdate(),
    EmployeeSex nvarchar(1) not null check(EmployeeSex in ('M', 'F')),
    EmployeeSalary money not null check(EmployeeSalary >= 0) default 0
);
go;

create table Clients
(
    ClientID int identity(1, 1) not null primary key,
    ClientSNP nvarchar(40) not null,
    ClientEmail nvarchar(40) not null,
    ClientPhone nvarchar(20) not null,
    ClientSex nvarchar(1) not null check(ClientSex in ('M', 'F')),
    ClientOrderHistory int not null check(ClientOrderHistory >= 0) default 0,
    ClientDiscountPercent int not null check(ClientDiscountPercent >= 0 and ClientDiscountPercent <= 100) default 0,
    ClientIsSubscribed bit not null default 0
);

create table Sales
(
    SaleID int identity(1, 1) not null primary key,
    ProductID int not null foreign key references Products(ProductID),
    ProductSellingPrice money not null foreign key references Products(ProductSellingPrice),
    SaleDate date not null default getdate(),
    EmployeeID int not null foreign key references Employees(EmployeeID),
    ClientID int not null foreign key references Clients(ClientID),
);
go;

create table History
(
    HistoryID int identity(1, 1) not null primary key,
    ProductID int not null foreign key references Products(ProductID),
    ProductSellingPrice money not null,
    SaleDate date not null,
    EmployeeID int not null foreign key references Employees(EmployeeID),
    ClientID int not null foreign key references Clients(ClientID)
);
go;

create table Archive
(
    ArchiveID int identity(1, 1) not null primary key,
    ProductID int not null foreign key references Products(ProductID),
    ProductName nvarchar(20) not null,
    ProductType nvarchar(20) not null,
    ProductProducer nvarchar(20) not null,
    SaleDate date not null,
);
go;

create trigger trg_SalesHistory
on Sales
after insert
as
begin
    insert into History (ProductID, ProductSellingPrice, SaleDate, EmployeeID, ClientID)
    select ProductID, ProductSellingPrice, SaleDate, EmployeeID, ClientID
    from inserted;
end;
go;

create trigger trg_ArchiveSoldOutProducts
on Sales
after insert
as
begin
    insert into Archive (ProductID, ProductName, ProductType, ProductProducer, SaleDate)
    select p.ProductID, p.ProductName, p.ProductType, p.ProductProducer, i.SaleDate
    from Products p
    join inserted i on p.ProductID = i.ProductID
    where p.ProductAvailable = 0;
end;
go;
