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

create table LastUnit
(
    LastUnitID int identity(1, 1) not null primary key,
    ProductID int not null foreign key references Products(ProductID),
    ProductName nvarchar(20) not null,
    ProductType nvarchar(20) not null,
    ProductProducer nvarchar(20) not null,
    SaleDate date not null
);
go;

create table EmployeeArchive
(
    ArchiveID int identity(1, 1) not null primary key,
    EmployeeID int not null,
    EmployeeSNP nvarchar(40) not null,
    EmployeePosition nvarchar(20) not null,
    EmployeeEmploymentDate date not null,
    EmployeeSex nvarchar(1) not null,
    EmployeeSalary money not null,
    ArchiveDate date not null default getdate()
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

create unique index idx_UniqueClient
on Clients(ClientEmail);

create trigger trg_PreventClientDeletion
on Clients
    for delete
as
begin
    if exists (select * from deleted)
    begin
        raiserror('You cannot delete a client', 16, 1);
        rollback transaction;
    end;
end;
go;

create trigger trg_PreventEmployeeDeletion
on Employees
    for delete
as
begin
    if exists (select 1 from deleted where EmployeeEmploymentDate < '2015-01-01')
    begin
        raiserror('You cannot delete an employee', 16, 1);
        rollback transaction;
    end;
end;
go;

create trigger trg_PreventEmployeeDeletion
on Employees
for delete
as
begin
    if exists (select 1 from deleted where EmployeeEmploymentDate < '2015-01-01')
    begin
        raiserror('Deletion of employees hired before 2015 is not allowed.', 16, 1);
        rollback transaction;
    end
end;
go;

create trigger trg_UpdateClientDiscount
on Sales
after insert
as
begin
    update Clients
    set ClientDiscountPercent = 15
    where ClientID in (
        select s.ClientID
        from Sales s
        join inserted i on s.ClientID = i.ClientID
        group by s.ClientID
        having sum(s.ProductSellingPrice) > 50000
    );
end;
go;

create trigger trg_PreventSpecificProducer
    on Products
    instead of insert
    as
begin
    if exists (select 1 from inserted where ProductProducer = 'Спорт, сонце та штанга')
        begin
            raiserror('Додавання товару фірми "Спорт, сонце та штанга" заборонено.', 16, 1);
            rollback transaction;
        end
    else
        begin
            insert into Products (ProductName, ProductType, ProductAvailable, ProductCost, ProductSellingPrice, ProductProducer)
            select ProductName, ProductType, ProductAvailable, ProductCost, ProductSellingPrice, ProductProducer
            from inserted;
        end
end;
go;

create trigger trg_LastUnitAlert
on Sales
after insert
as
begin
    insert into LastUnit (ProductID, ProductName, ProductType, ProductProducer, SaleDate)
    select p.ProductID, p.ProductName, p.ProductType, p.ProductProducer, i.SaleDate
    from Products p
    join inserted i on p.ProductID = i.ProductID
    where p.ProductAvailable = 1;
end;
go;

create trigger trg_UpdateProductQuantity
on Products
instead of insert
as
begin
    update p
    set p.ProductAvailable = p.ProductAvailable + i.ProductAvailable
    from Products p
    join inserted i on p.ProductName = i.ProductName
                  and p.ProductType = i.ProductType
                  and p.ProductProducer = i.ProductProducer;
    insert into Products (ProductName, ProductType, ProductAvailable, ProductCost, ProductSellingPrice, ProductProducer)
    select i.ProductName, i.ProductType, i.ProductAvailable, i.ProductCost, i.ProductSellingPrice, i.ProductProducer
    from inserted i
    where not exists (
        select 1
        from Products p
        where p.ProductName = i.ProductName
          and p.ProductType = i.ProductType
          and p.ProductProducer = i.ProductProducer
    );
end;
go;

create trigger trg_ArchiveEmployee
on Employees
for delete
as
begin
    insert into EmployeeArchive (EmployeeID, EmployeeSNP, EmployeePosition, EmployeeEmploymentDate, EmployeeSex, EmployeeSalary)
    select EmployeeID, EmployeeSNP, EmployeePosition, EmployeeEmploymentDate, EmployeeSex, EmployeeSalary
    from deleted;
end;
go;

create trigger trg_PreventExcessSellers
on Employees
for insert
as
begin
    if (select count(*) from Employees where EmployeePosition = 'Seller') > 6
    begin
        raiserror('Cannot add more sellers: Maximum limit of 6 sellers reached.', 16, 1);
        rollback transaction;
    end
end;
go;