USE master;
GO

IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = N'DVLD')
BEGIN
    CREATE DATABASE DVLD;
END
GO

USE DVLD;
GO

-- ============================================================================
-- 1. DDL: TABLE DEFINITIONS
-- ============================================================================

-- Drop tables if they already exist (reverse dependency order)
IF OBJECT_ID('FK_RetakeTestOrders_TestAppointments', 'F') IS NOT NULL
    ALTER TABLE RetakeTestOrders DROP CONSTRAINT FK_RetakeTestOrders_TestAppointments;
IF OBJECT_ID('FK_TestAppointments_RetakeTestOrders', 'F') IS NOT NULL
    ALTER TABLE TestAppointments DROP CONSTRAINT FK_TestAppointments_RetakeTestOrders;
GO

IF OBJECT_ID('Tests', 'U') IS NOT NULL DROP TABLE Tests;
IF OBJECT_ID('TestAppointments', 'U') IS NOT NULL DROP TABLE TestAppointments;
IF OBJECT_ID('RetakeTestOrders', 'U') IS NOT NULL DROP TABLE RetakeTestOrders;
IF OBJECT_ID('LicenseServiceOrders', 'U') IS NOT NULL DROP TABLE LicenseServiceOrders;
IF OBJECT_ID('NewLicenseOrders', 'U') IS NOT NULL DROP TABLE NewLicenseOrders;
IF OBJECT_ID('InternationalLicenses', 'U') IS NOT NULL DROP TABLE InternationalLicenses;
IF OBJECT_ID('DetainedLicenses', 'U') IS NOT NULL DROP TABLE DetainedLicenses;
IF OBJECT_ID('DrivingLicenses', 'U') IS NOT NULL DROP TABLE DrivingLicenses;
IF OBJECT_ID('Drivers', 'U') IS NOT NULL DROP TABLE Drivers;
IF OBJECT_ID('ServiceOrders', 'U') IS NOT NULL DROP TABLE ServiceOrders;
IF OBJECT_ID('Users', 'U') IS NOT NULL DROP TABLE Users;
IF OBJECT_ID('People', 'U') IS NOT NULL DROP TABLE People;
IF OBJECT_ID('Countries', 'U') IS NOT NULL DROP TABLE Countries;
IF OBJECT_ID('LicenseIssueReasons', 'U') IS NOT NULL DROP TABLE LicenseIssueReasons;
IF OBJECT_ID('TestTypes', 'U') IS NOT NULL DROP TABLE TestTypes;
IF OBJECT_ID('OrderStatuses', 'U') IS NOT NULL DROP TABLE OrderStatuses;
IF OBJECT_ID('LicenseClasses', 'U') IS NOT NULL DROP TABLE LicenseClasses;
IF OBJECT_ID('Services', 'U') IS NOT NULL DROP TABLE Services;
GO

CREATE TABLE Countries (
    CountryID INT IDENTITY(1,1) PRIMARY KEY,
    CountryName NVARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE People (
    PersonID INT IDENTITY(1,1) PRIMARY KEY,
    NationalID NVARCHAR(20) NOT NULL UNIQUE,
    FirstName NVARCHAR(50) NOT NULL,
    SecondName NVARCHAR(50) NOT NULL,
    ThirdName NVARCHAR(50) NULL,
    LastName NVARCHAR(50) NOT NULL,
    BirthDate DATETIME NOT NULL,
    Gender TINYINT NOT NULL, -- 0: Male, 1: Female
    Address NVARCHAR(500) NOT NULL,
    Phone NVARCHAR(25) NOT NULL,
    Email NVARCHAR(100) NULL,
    NationalityCountryID INT NOT NULL FOREIGN KEY REFERENCES Countries(CountryID),
    ImagePath NVARCHAR(255) NULL
);

CREATE TABLE Users (
    UserID INT IDENTITY(1,1) PRIMARY KEY,
    PersonID INT NOT NULL UNIQUE FOREIGN KEY REFERENCES People(PersonID),
    UserName NVARCHAR(50) NOT NULL UNIQUE,
    Password NVARCHAR(128) NOT NULL,
    IsActive BIT NOT NULL DEFAULT 1,
    Permissions INT NOT NULL DEFAULT -1
);

CREATE TABLE OrderStatuses (
    OrderStatusID INT IDENTITY(1,1) PRIMARY KEY,
    Status NVARCHAR(50) NOT NULL
);

CREATE TABLE Services (
    ServiceID INT IDENTITY(1,1) PRIMARY KEY,
    ServiceName NVARCHAR(150) NOT NULL,
    Cost SMALLMONEY NOT NULL
);

CREATE TABLE LicenseClasses (
    LicenseClassID INT IDENTITY(1,1) PRIMARY KEY,
    ClassName NVARCHAR(100) NOT NULL,
    ClassDescription NVARCHAR(500) NOT NULL,
    MinimumAllowedAge TINYINT NOT NULL,
    ValidityLength TINYINT NOT NULL,
    ClassFees SMALLMONEY NOT NULL
);

CREATE TABLE TestTypes (
    TestTypeID INT IDENTITY(1,1) PRIMARY KEY,
    TestTypeName NVARCHAR(100) NOT NULL,
    Cost SMALLMONEY NOT NULL,
    Description NVARCHAR(500) NOT NULL
);

CREATE TABLE LicenseIssueReasons (
    IssueReasonID INT IDENTITY(1,1) PRIMARY KEY,
    ReasonTitle NVARCHAR(100) NOT NULL
);

CREATE TABLE Drivers (
    DriverID INT IDENTITY(1,1) PRIMARY KEY,
    PersonID INT NOT NULL UNIQUE FOREIGN KEY REFERENCES People(PersonID),
    CreatedBy INT NOT NULL FOREIGN KEY REFERENCES Users(UserID),
    CreatedDate DATETIME NOT NULL DEFAULT GETDATE()
);

CREATE TABLE ServiceOrders (
    OrderID INT IDENTITY(1,1) PRIMARY KEY,
    ServiceID INT NOT NULL FOREIGN KEY REFERENCES Services(ServiceID),
    PersonID INT NOT NULL FOREIGN KEY REFERENCES People(PersonID),
    OrderDate DATETIME NOT NULL DEFAULT GETDATE(),
    OrderStatus INT NOT NULL FOREIGN KEY REFERENCES OrderStatuses(OrderStatusID),
    LastStatusDate DATETIME NOT NULL DEFAULT GETDATE(),
    OrderFee SMALLMONEY NOT NULL,
    CreatedBy INT NOT NULL FOREIGN KEY REFERENCES Users(UserID)
);

CREATE TABLE NewLicenseOrders (
    OrderID INT PRIMARY KEY FOREIGN KEY REFERENCES ServiceOrders(OrderID) ON DELETE CASCADE,
    LicenseClassID INT NOT NULL FOREIGN KEY REFERENCES LicenseClasses(LicenseClassID)
);

CREATE TABLE DrivingLicenses (
    LicenseID INT IDENTITY(1,1) PRIMARY KEY,
    OrderID INT NOT NULL FOREIGN KEY REFERENCES ServiceOrders(OrderID),
    LicenseClassID INT NOT NULL FOREIGN KEY REFERENCES LicenseClasses(LicenseClassID),
    IssueDate DATETIME NOT NULL DEFAULT GETDATE(),
    ExpirationDate DATETIME NOT NULL,
    IssueReasonID INT NOT NULL FOREIGN KEY REFERENCES LicenseIssueReasons(IssueReasonID),
    DriverID INT NOT NULL FOREIGN KEY REFERENCES Drivers(DriverID),
    Notes NVARCHAR(500) NULL,
    CreatedBy INT NOT NULL FOREIGN KEY REFERENCES Users(UserID),
    IsActive BIT NOT NULL DEFAULT 1,
    Cost SMALLMONEY NOT NULL
);

CREATE TABLE LicenseServiceOrders (
    OrderID INT PRIMARY KEY FOREIGN KEY REFERENCES ServiceOrders(OrderID) ON DELETE CASCADE,
    OldLicenseID INT NOT NULL FOREIGN KEY REFERENCES DrivingLicenses(LicenseID)
);

CREATE TABLE RetakeTestOrders (
    OrderID INT PRIMARY KEY FOREIGN KEY REFERENCES ServiceOrders(OrderID) ON DELETE CASCADE,
    PreviousAppointmentID INT NOT NULL
);

CREATE TABLE TestAppointments (
    AppointmentID INT IDENTITY(1,1) PRIMARY KEY,
    TestTypeID INT NOT NULL FOREIGN KEY REFERENCES TestTypes(TestTypeID),
    OrderID INT NOT NULL FOREIGN KEY REFERENCES ServiceOrders(OrderID),
    IsLocked BIT NOT NULL DEFAULT 0,
    TestFee SMALLMONEY NOT NULL,
    TestDate DATETIME NOT NULL,
    CreatedBy INT NOT NULL FOREIGN KEY REFERENCES Users(UserID),
    RetakeTestOrderID INT NULL
);

-- Add mutual constraints between TestAppointments and RetakeTestOrders
ALTER TABLE RetakeTestOrders ADD CONSTRAINT FK_RetakeTestOrders_TestAppointments
    FOREIGN KEY (PreviousAppointmentID) REFERENCES TestAppointments(AppointmentID);
ALTER TABLE TestAppointments ADD CONSTRAINT FK_TestAppointments_RetakeTestOrders
    FOREIGN KEY (RetakeTestOrderID) REFERENCES RetakeTestOrders(OrderID);

CREATE TABLE Tests (
    TestID INT IDENTITY(1,1) PRIMARY KEY,
    TestAppointmentID INT NOT NULL UNIQUE FOREIGN KEY REFERENCES TestAppointments(AppointmentID),
    TestResult BIT NOT NULL, -- 1: Pass, 0: Fail
    Notes NVARCHAR(500) NULL,
    CreatedBy INT NOT NULL FOREIGN KEY REFERENCES Users(UserID),
    TestDate DATETIME NOT NULL DEFAULT GETDATE()
);

CREATE TABLE DetainedLicenses (
    DetainID INT IDENTITY(1,1) PRIMARY KEY,
    LicenseID INT NOT NULL FOREIGN KEY REFERENCES DrivingLicenses(LicenseID),
    DetainDate DATETIME NOT NULL DEFAULT GETDATE(),
    FineFees SMALLMONEY NOT NULL,
    CreatedBy INT NOT NULL FOREIGN KEY REFERENCES Users(UserID),
    ReleasedBy INT NULL FOREIGN KEY REFERENCES Users(UserID),
    IsReleased BIT NOT NULL DEFAULT 0,
    ReleaseDate DATETIME NULL,
    ReleaseOrderID INT NULL FOREIGN KEY REFERENCES ServiceOrders(OrderID),
    DetainReason NVARCHAR(500) NULL
);

CREATE TABLE InternationalLicenses (
    InternationalLicenseID INT IDENTITY(1,1) PRIMARY KEY,
    OrderID INT NOT NULL FOREIGN KEY REFERENCES ServiceOrders(OrderID),
    DriverID INT NOT NULL FOREIGN KEY REFERENCES Drivers(DriverID),
    IssuedUsingLocalLicenseID INT NOT NULL FOREIGN KEY REFERENCES DrivingLicenses(LicenseID),
    IssueDate DATETIME NOT NULL DEFAULT GETDATE(),
    ExpirationDate DATETIME NOT NULL,
    IsActive BIT NOT NULL DEFAULT 1,
    CreatedBy INT NOT NULL FOREIGN KEY REFERENCES Users(UserID)
);
GO

-- ============================================================================
-- 2. DML: LOOKUP DATA FROM REQUIREMENTS PDF
-- ============================================================================

SET IDENTITY_INSERT OrderStatuses ON;
INSERT INTO OrderStatuses (OrderStatusID, Status) VALUES
(1, N'New'),
(2, N'Cancelled'),
(3, N'Completed');
SET IDENTITY_INSERT OrderStatuses OFF;

SET IDENTITY_INSERT Services ON;
INSERT INTO Services (ServiceID, ServiceName, Cost) VALUES
(1, N'New Local Driving License Service', 15.0000),
(2, N'Renew Driving License Service', 10.0000),
(3, N'Replacement for a Lost Driving License Service', 20.0000),
(4, N'Replacement for a Damaged Driving License Service', 20.0000),
(5, N'Release Detained Driving License Service', 15.0000),
(6, N'New International License Service', 20.0000),
(7, N'Retake Test Service', 5.0000);
SET IDENTITY_INSERT Services OFF;

SET IDENTITY_INSERT LicenseClasses ON;
INSERT INTO LicenseClasses (LicenseClassID, ClassName, ClassDescription, MinimumAllowedAge, ValidityLength, ClassFees) VALUES
(1, N'Class 1 - Small Motorcycle', N'Allows the driver to drive small motorcycles with limited capacity and power.', 18, 5, 15.0000),
(2, N'Class 2 - Heavy Motorcycle License', N'Allows the driver to drive large and heavy motorcycles.', 21, 5, 30.0000),
(3, N'Class 3 - Ordinary driving license', N'Allows the driver to drive personal vehicles and light vehicles.', 18, 10, 20.0000),
(4, N'Class 4 - Commercial', N'Allows the driver to drive taxi and limousine vehicles.', 21, 10, 200.0000),
(5, N'Class 5 - Agricultural', N'Allows the driver to drive tractors and agricultural machinery.', 21, 10, 50.0000),
(6, N'Class 6 - Small and medium bus', N'Allows the driver to drive small and medium-sized buses.', 21, 10, 250.0000),
(7, N'Class 7 - Truck and heavy vehicle', N'Allows the driver to drive large trucks and heavy transport vehicles.', 21, 10, 300.0000);
SET IDENTITY_INSERT LicenseClasses OFF;

SET IDENTITY_INSERT TestTypes ON;
INSERT INTO TestTypes (TestTypeID, TestTypeName, Cost, Description) VALUES
(1, N'Vision Test', 10.0000, N'Medical eye examination to verify driver visual acuity and fitness.'),
(2, N'Written (Theory) Test', 20.0000, N'Theoretical exam on road signs, safe driving principles, and traffic laws.'),
(3, N'Practical (Street) Test', 30.0000, N'Field driving examination to assess driver vehicle handling and road safety compliance.');
SET IDENTITY_INSERT TestTypes OFF;

SET IDENTITY_INSERT LicenseIssueReasons ON;
INSERT INTO LicenseIssueReasons (IssueReasonID, ReasonTitle) VALUES
(1, N'First Time'),
(2, N'Renew'),
(3, N'Replacement for Damaged'),
(4, N'Replacement for Lost');
SET IDENTITY_INSERT LicenseIssueReasons OFF;

SET IDENTITY_INSERT Countries ON;
INSERT INTO Countries (CountryID, CountryName) VALUES
(1, N'Jordan'), (2, N'Palestine'), (3, N'Saudi Arabia'), (4, N'Egypt'), (5, N'United Arab Emirates'),
(6, N'Kuwait'), (7, N'Qatar'), (8, N'Bahrain'), (9, N'Oman'), (10, N'Lebanon'),
(11, N'Syria'), (12, N'Iraq'), (13, N'Morocco'), (14, N'Tunisia'), (15, N'Algeria'),
(16, N'United States'), (17, N'United Kingdom'), (18, N'Canada'), (19, N'Germany'), (20, N'France');
SET IDENTITY_INSERT Countries OFF;
GO

-- ============================================================================
-- 3. DML: SAMPLE OPERATIONAL DATA
-- ============================================================================

SET IDENTITY_INSERT People ON;
INSERT INTO People (PersonID, NationalID, FirstName, SecondName, ThirdName, LastName, BirthDate, Gender, Address, Phone, Email, NationalityCountryID, ImagePath) VALUES
(1, N'N1001', N'Omar', N'Khaled', N'Ahmad', N'Al-Masri', '1990-05-14', 0, N'Wasfi Al-Tal St, Amman', N'+962791112233', N'omar.masri@licensehub.jo', 1, NULL),
(2, N'N1002', N'Fatima', N'Zahra', N'Mahmoud', N'Khatib', '1988-11-20', 1, N'University St, Irbid', N'+962782223344', N'fatima.khatib@licensehub.jo', 1, NULL),
(3, N'N1003', N'Yousef', N'Ibrahim', N'Hassan', N'Tarawneh', '1995-03-22', 0, N'Al-Madina Al-Monawara St, Amman', N'+962773334455', N'yousef.t@licensehub.jo', 1, NULL),
(4, N'N1004', N'Rania', N'Sami', N'Tareq', N'Majali', '1992-09-08', 1, N'King Abdullah II St, Zarqa', N'+962794445566', N'rania.majali@licensehub.jo', 1, NULL),
(5, N'N1005', N'Ahmad', N'Saleh', N'Mustafa', N'Qudah', '1985-07-19', 0, N'Yarmouk Highway, Jerash', N'+962785556677', N'ahmad.qudah@licensehub.jo', 1, NULL),
(6, N'N1006', N'Tariq', N'Ziad', N'Faris', N'Hadidi', '1993-01-30', 0, N'Mecca St, Amman', N'+962797778899', N'tariq.hadidi@gmail.com', 1, NULL),
(7, N'N1007', N'Huda', N'Munir', N'Bassem', N'Abbadi', '1996-06-17', 1, N'Queen Rania St, Amman', N'+962788889900', N'huda.abbadi@gmail.com', 1, NULL),
(8, N'N1008', N'Kareem', N'Nasser', N'Suleiman', N'Dweik', '1991-04-11', 0, N'Zahran St, Amman', N'+962779990011', N'kareem.dweik@yahoo.com', 1, NULL),
(9, N'N1009', N'Sarah', N'Adnan', N'Fouad', N'Jabari', '2000-08-25', 1, N'Baghdad St, Zarqa', N'+962790001122', N'sarah.jabari@hotmail.com', 1, NULL),
(10, N'N1010', N'Hamza', N'Bilal', N'Rashid', N'Shawish', '2002-10-15', 0, N'Palestine St, Irbid', N'+962781113355', N'hamza.s@gmail.com', 1, NULL),
(11, N'N1011', N'Dina', N'Emad', N'Kamel', N'Barakat', '2001-05-20', 1, N'Gardens St, Amman', N'+962796668800', N'dina.barakat@gmail.com', 1, NULL),
(12, N'N1012', N'Rami', N'Ayman', N'Tayseer', N'Husseini', '1989-12-14', 0, N'Main St, Ramallah', N'+970599112233', N'rami.husseini@palnet.com', 2, NULL);
SET IDENTITY_INSERT People OFF;

SET IDENTITY_INSERT Users ON;
INSERT INTO Users (UserID, PersonID, UserName, Password, IsActive, Permissions) VALUES
(1, 1, N'admin', N'admin123', 1, -1),
(2, 2, N'fatima.k', N'fatima123', 1, -1),
(3, 3, N'yousef.t', N'yousef123', 1, 15);
SET IDENTITY_INSERT Users OFF;

SET IDENTITY_INSERT Drivers ON;
INSERT INTO Drivers (DriverID, PersonID, CreatedBy, CreatedDate) VALUES
(1, 6, 1, '2023-01-15 10:30:00'),
(2, 7, 2, '2023-02-10 11:15:00'),
(3, 8, 3, '2023-03-05 09:45:00'),
(4, 9, 1, '2023-04-12 14:20:00'),
(5, 10, 2, '2023-05-18 08:30:00');
SET IDENTITY_INSERT Drivers OFF;

SET IDENTITY_INSERT ServiceOrders ON;
INSERT INTO ServiceOrders (OrderID, ServiceID, PersonID, OrderDate, OrderStatus, LastStatusDate, OrderFee, CreatedBy) VALUES
-- New License Orders (Completed)
(1, 1, 6, '2023-01-02 09:00:00', 3, '2023-01-15 10:30:00', 15.0000, 1),
(2, 1, 7, '2023-01-20 10:15:00', 3, '2023-02-10 11:15:00', 15.0000, 2),
(3, 1, 8, '2023-02-15 08:30:00', 3, '2023-03-05 09:45:00', 15.0000, 3),
(4, 1, 9, '2023-03-10 11:00:00', 3, '2023-04-12 14:20:00', 15.0000, 1),
(5, 1, 10, '2023-04-05 09:30:00', 3, '2023-05-18 08:30:00', 15.0000, 2),
-- Retake Test Order
(6, 7, 8, '2023-02-25 11:00:00', 3, '2023-02-25 11:00:00', 5.0000, 3),
-- Renew License Order
(7, 2, 6, '2024-01-10 09:30:00', 3, '2024-01-10 10:00:00', 10.0000, 1),
-- Replace Lost License Order
(8, 3, 7, '2024-02-14 11:20:00', 3, '2024-02-14 12:00:00', 20.0000, 2),
-- Release Detained License Order
(9, 5, 8, '2024-04-05 15:30:00', 3, '2024-04-05 15:45:00', 15.0000, 1),
-- International License Order
(10, 6, 6, '2024-02-01 10:00:00', 3, '2024-02-01 10:30:00', 20.0000, 1),
-- In-Progress Application
(11, 1, 11, '2024-06-01 09:00:00', 1, '2024-06-01 09:00:00', 15.0000, 3);
SET IDENTITY_INSERT ServiceOrders OFF;

INSERT INTO NewLicenseOrders (OrderID, LicenseClassID) VALUES
(1, 3), (2, 3), (3, 1), (4, 3), (5, 2), (11, 3);

SET IDENTITY_INSERT DrivingLicenses ON;
INSERT INTO DrivingLicenses (LicenseID, OrderID, LicenseClassID, IssueDate, ExpirationDate, IssueReasonID, DriverID, Notes, CreatedBy, IsActive, Cost) VALUES
(1, 1, 3, '2023-01-15 10:30:00', '2033-01-15 10:30:00', 1, 1, N'First time issuance.', 1, 0, 20.0000), -- Renewed by #6
(2, 2, 3, '2023-02-10 11:15:00', '2033-02-10 11:15:00', 1, 2, N'Corrective lenses required.', 2, 0, 20.0000), -- Replaced by #7
(3, 3, 1, '2023-03-05 09:45:00', '2028-03-05 09:45:00', 1, 3, N'Small motorcycle.', 3, 1, 15.0000),
(4, 4, 3, '2023-04-12 14:20:00', '2033-04-12 14:20:00', 1, 4, N'Standard vehicle license.', 1, 1, 20.0000),
(5, 5, 2, '2023-05-18 08:30:00', '2028-05-18 08:30:00', 1, 5, N'Heavy motorcycle certified.', 2, 1, 30.0000),
(6, 7, 3, '2024-01-10 10:00:00', '2034-01-10 10:00:00', 2, 1, N'Renewed driving license.', 1, 1, 20.0000),
(7, 8, 3, '2024-02-14 12:00:00', '2033-02-10 11:15:00', 4, 2, N'Replacement for lost license.', 2, 1, 20.0000);
SET IDENTITY_INSERT DrivingLicenses OFF;

INSERT INTO LicenseServiceOrders (OrderID, OldLicenseID) VALUES
(7, 1), (8, 2);

SET IDENTITY_INSERT TestAppointments ON;
INSERT INTO TestAppointments (AppointmentID, TestTypeID, OrderID, IsLocked, TestFee, TestDate, CreatedBy, RetakeTestOrderID) VALUES
(1, 1, 1, 1, 10.0000, '2023-01-05 09:00:00', 1, NULL),
(2, 2, 1, 1, 20.0000, '2023-01-10 10:00:00', 1, NULL),
(3, 3, 1, 1, 30.0000, '2023-01-15 09:30:00', 1, NULL),
(4, 1, 3, 1, 10.0000, '2023-02-20 09:00:00', 3, NULL), -- Failed Vision
(5, 1, 3, 1, 10.0000, '2023-02-26 09:30:00', 3, NULL), -- Retake Vision
(6, 2, 3, 1, 20.0000, '2023-03-01 11:00:00', 3, NULL),
(7, 3, 3, 1, 30.0000, '2023-03-05 09:00:00', 3, NULL),
(8, 1, 11, 1, 10.0000, '2024-06-03 09:00:00', 3, NULL), -- In-progress Vision passed
(9, 2, 11, 0, 20.0000, '2026-10-15 10:00:00', 3, NULL); -- In-progress Theory scheduled
SET IDENTITY_INSERT TestAppointments OFF;

INSERT INTO RetakeTestOrders (OrderID, PreviousAppointmentID) VALUES
(6, 4);

UPDATE TestAppointments SET RetakeTestOrderID = 6 WHERE AppointmentID = 5;

SET IDENTITY_INSERT Tests ON;
INSERT INTO Tests (TestID, TestAppointmentID, TestResult, Notes, CreatedBy, TestDate) VALUES
(1, 1, 1, N'Vision passed.', 1, '2023-01-05 09:20:00'),
(2, 2, 1, N'Theory score: 96/100.', 1, '2023-01-10 10:35:00'),
(3, 3, 1, N'Practical exam passed.', 1, '2023-01-15 10:15:00'),
(4, 4, 0, N'Failed vision acuity.', 3, '2023-02-20 09:15:00'),
(5, 5, 1, N'Vision passed with glasses.', 3, '2023-02-26 09:45:00'),
(6, 6, 1, N'Theory score: 88/100.', 3, '2023-03-01 11:30:00'),
(7, 7, 1, N'Practical exam passed.', 3, '2023-03-05 09:30:00'),
(8, 8, 1, N'Vision passed.', 3, '2024-06-03 09:15:00');
SET IDENTITY_INSERT Tests OFF;

SET IDENTITY_INSERT DetainedLicenses ON;
INSERT INTO DetainedLicenses (DetainID, LicenseID, DetainDate, FineFees, CreatedBy, ReleasedBy, IsReleased, ReleaseDate, ReleaseOrderID, DetainReason) VALUES
(1, 3, '2024-03-20 14:00:00', 100.0000, 1, 1, 1, '2024-04-05 15:45:00', 9, N'Exceeding speed limit.'),
(2, 4, '2024-05-02 08:30:00', 250.0000, 1, NULL, 0, NULL, NULL, N'Driving without safety permit.');
SET IDENTITY_INSERT DetainedLicenses OFF;

SET IDENTITY_INSERT InternationalLicenses ON;
INSERT INTO InternationalLicenses (InternationalLicenseID, OrderID, DriverID, IssuedUsingLocalLicenseID, IssueDate, ExpirationDate, IsActive, CreatedBy) VALUES
(1, 10, 1, 6, '2024-02-01 10:30:00', '2025-02-01 10:30:00', 1, 1);
SET IDENTITY_INSERT InternationalLicenses OFF;
GO
