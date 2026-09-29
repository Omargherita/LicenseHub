/*
================================================================================
  DATABASE CREATION AND POPULATION SCRIPT
  Project: LicenseHub / DVLD (Driving & Vehicle License Department)
  Engine: Microsoft SQL Server (SSMS compatible)
  Modeled From: ProjectDesign.drawio & DVLD Requirements Specification
================================================================================
*/

USE master;
GO

IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = N'DVLD')
BEGIN
    CREATE DATABASE DVLD;
    PRINT 'Database [DVLD] created successfully.';
END
ELSE
BEGIN
    PRINT 'Database [DVLD] already exists.';
END
GO

USE DVLD;
GO

-- ============================================================================
-- 1. DROP EXISTING VIEWS AND TABLES (Clean Idempotent Setup)
-- ============================================================================
IF OBJECT_ID('vw_LocalDrivingLicenseApplications', 'V') IS NOT NULL DROP VIEW vw_LocalDrivingLicenseApplications;
IF OBJECT_ID('vw_DrivingLicenses', 'V') IS NOT NULL DROP VIEW vw_DrivingLicenses;
IF OBJECT_ID('vw_InternationalLicenses', 'V') IS NOT NULL DROP VIEW vw_InternationalLicenses;
IF OBJECT_ID('vw_DetainedLicenses', 'V') IS NOT NULL DROP VIEW vw_DetainedLicenses;
IF OBJECT_ID('vw_TestAppointments', 'V') IS NOT NULL DROP VIEW vw_TestAppointments;
IF OBJECT_ID('vw_Drivers', 'V') IS NOT NULL DROP VIEW vw_Drivers;
IF OBJECT_ID('vw_Users', 'V') IS NOT NULL DROP VIEW vw_Users;
GO

-- Drop mutual FK constraints before dropping tables
IF OBJECT_ID('FK_TestAppointments_RetakeTestOrders', 'F') IS NOT NULL
    ALTER TABLE TestAppointments DROP CONSTRAINT FK_TestAppointments_RetakeTestOrders;
IF OBJECT_ID('FK_RetakeTestOrders_TestAppointments', 'F') IS NOT NULL
    ALTER TABLE RetakeTestOrders DROP CONSTRAINT FK_RetakeTestOrders_TestAppointments;
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

-- ============================================================================
-- 2. DDL TABLE DEFINITIONS (All 18 Tables from ProjectDesign.drawio)
-- ============================================================================

-- 2.1 Countries Table
CREATE TABLE Countries (
    CountryID INT IDENTITY(1,1) NOT NULL,
    CountryName NVARCHAR(100) NOT NULL,
    CONSTRAINT PK_Countries PRIMARY KEY CLUSTERED (CountryID ASC),
    CONSTRAINT UQ_Countries_CountryName UNIQUE (CountryName)
);
GO

-- 2.2 People Table
CREATE TABLE People (
    PersonID INT IDENTITY(1,1) NOT NULL,
    NationalID NVARCHAR(20) NOT NULL,
    FirstName NVARCHAR(50) NOT NULL,
    SecondName NVARCHAR(50) NOT NULL,
    ThirdName NVARCHAR(50) NULL,
    LastName NVARCHAR(50) NOT NULL,
    BirthDate DATETIME NOT NULL,
    Gender TINYINT NOT NULL, -- 0: Male, 1: Female
    Address NVARCHAR(500) NOT NULL,
    Phone NVARCHAR(25) NOT NULL,
    Email NVARCHAR(100) NULL,
    NationalityCountryID INT NOT NULL,
    ImagePath NVARCHAR(255) NULL,
    CONSTRAINT PK_People PRIMARY KEY CLUSTERED (PersonID ASC),
    CONSTRAINT UQ_People_NationalID UNIQUE (NationalID),
    CONSTRAINT FK_People_Countries FOREIGN KEY (NationalityCountryID) REFERENCES Countries (CountryID)
);
GO

-- 2.3 Users Table
CREATE TABLE Users (
    UserID INT IDENTITY(1,1) NOT NULL,
    PersonID INT NOT NULL,
    UserName NVARCHAR(50) NOT NULL,
    Password NVARCHAR(128) NOT NULL,
    IsActive BIT NOT NULL CONSTRAINT DF_Users_IsActive DEFAULT (1),
    Permissions INT NOT NULL CONSTRAINT DF_Users_Permissions DEFAULT (-1),
    CONSTRAINT PK_Users PRIMARY KEY CLUSTERED (UserID ASC),
    CONSTRAINT UQ_Users_PersonID UNIQUE (PersonID),
    CONSTRAINT UQ_Users_UserName UNIQUE (UserName),
    CONSTRAINT FK_Users_People FOREIGN KEY (PersonID) REFERENCES People (PersonID)
);
GO

-- 2.4 OrderStatuses Table
CREATE TABLE OrderStatuses (
    OrderStatusID INT IDENTITY(1,1) NOT NULL,
    Status NVARCHAR(50) NOT NULL,
    CONSTRAINT PK_OrderStatuses PRIMARY KEY CLUSTERED (OrderStatusID ASC)
);
GO

-- 2.5 Services Table
CREATE TABLE Services (
    ServiceID INT IDENTITY(1,1) NOT NULL,
    ServiceName NVARCHAR(150) NOT NULL,
    Cost SMALLMONEY NOT NULL,
    CONSTRAINT PK_Services PRIMARY KEY CLUSTERED (ServiceID ASC)
);
GO

-- 2.6 LicenseClasses Table
CREATE TABLE LicenseClasses (
    LicenseClassID INT IDENTITY(1,1) NOT NULL,
    ClassName NVARCHAR(100) NOT NULL,
    ClassDescription NVARCHAR(500) NOT NULL,
    MinimumAllowedAge TINYINT NOT NULL,
    ValidityLength TINYINT NOT NULL,
    ClassFees SMALLMONEY NOT NULL,
    CONSTRAINT PK_LicenseClasses PRIMARY KEY CLUSTERED (LicenseClassID ASC)
);
GO

-- 2.7 TestTypes Table
CREATE TABLE TestTypes (
    TestTypeID INT IDENTITY(1,1) NOT NULL,
    TestTypeName NVARCHAR(100) NOT NULL,
    Cost SMALLMONEY NOT NULL,
    Description NVARCHAR(500) NOT NULL,
    CONSTRAINT PK_TestTypes PRIMARY KEY CLUSTERED (TestTypeID ASC)
);
GO

-- 2.8 LicenseIssueReasons Table
CREATE TABLE LicenseIssueReasons (
    IssueReasonID INT IDENTITY(1,1) NOT NULL,
    ReasonTitle NVARCHAR(100) NOT NULL,
    CONSTRAINT PK_LicenseIssueReasons PRIMARY KEY CLUSTERED (IssueReasonID ASC)
);
GO

-- 2.9 Drivers Table
CREATE TABLE Drivers (
    DriverID INT IDENTITY(1,1) NOT NULL,
    PersonID INT NOT NULL,
    CreatedBy INT NOT NULL,
    CreatedDate DATETIME NOT NULL CONSTRAINT DF_Drivers_CreatedDate DEFAULT (GETDATE()),
    CONSTRAINT PK_Drivers PRIMARY KEY CLUSTERED (DriverID ASC),
    CONSTRAINT UQ_Drivers_PersonID UNIQUE (PersonID),
    CONSTRAINT FK_Drivers_People FOREIGN KEY (PersonID) REFERENCES People (PersonID),
    CONSTRAINT FK_Drivers_Users FOREIGN KEY (CreatedBy) REFERENCES Users (UserID)
);
GO

-- 2.10 ServiceOrders Table
CREATE TABLE ServiceOrders (
    OrderID INT IDENTITY(1,1) NOT NULL,
    ServiceID INT NOT NULL,
    PersonID INT NOT NULL,
    OrderDate DATETIME NOT NULL CONSTRAINT DF_ServiceOrders_OrderDate DEFAULT (GETDATE()),
    OrderStatus INT NOT NULL,
    LastStatusDate DATETIME NOT NULL CONSTRAINT DF_ServiceOrders_LastStatusDate DEFAULT (GETDATE()),
    OrderFee SMALLMONEY NOT NULL,
    CreatedBy INT NOT NULL,
    CONSTRAINT PK_ServiceOrders PRIMARY KEY CLUSTERED (OrderID ASC),
    CONSTRAINT FK_ServiceOrders_Services FOREIGN KEY (ServiceID) REFERENCES Services (ServiceID),
    CONSTRAINT FK_ServiceOrders_People FOREIGN KEY (PersonID) REFERENCES People (PersonID),
    CONSTRAINT FK_ServiceOrders_OrderStatuses FOREIGN KEY (OrderStatus) REFERENCES OrderStatuses (OrderStatusID),
    CONSTRAINT FK_ServiceOrders_Users FOREIGN KEY (CreatedBy) REFERENCES Users (UserID)
);
GO

-- 2.11 NewLicenseOrders Table (TPT Subtype of ServiceOrders)
CREATE TABLE NewLicenseOrders (
    OrderID INT NOT NULL,
    LicenseClassID INT NOT NULL,
    CONSTRAINT PK_NewLicenseOrders PRIMARY KEY CLUSTERED (OrderID ASC),
    CONSTRAINT FK_NewLicenseOrders_ServiceOrders FOREIGN KEY (OrderID) REFERENCES ServiceOrders (OrderID) ON DELETE CASCADE,
    CONSTRAINT FK_NewLicenseOrders_LicenseClasses FOREIGN KEY (LicenseClassID) REFERENCES LicenseClasses (LicenseClassID)
);
GO

-- 2.12 DrivingLicenses Table
CREATE TABLE DrivingLicenses (
    LicenseID INT IDENTITY(1,1) NOT NULL,
    OrderID INT NOT NULL,
    LicenseClassID INT NOT NULL,
    IssueDate DATETIME NOT NULL CONSTRAINT DF_DrivingLicenses_IssueDate DEFAULT (GETDATE()),
    ExpirationDate DATETIME NOT NULL,
    IssueReasonID INT NOT NULL,
    DriverID INT NOT NULL,
    Notes NVARCHAR(500) NULL,
    CreatedBy INT NOT NULL,
    IsActive BIT NOT NULL CONSTRAINT DF_DrivingLicenses_IsActive DEFAULT (1),
    Cost SMALLMONEY NOT NULL,
    CONSTRAINT PK_DrivingLicenses PRIMARY KEY CLUSTERED (LicenseID ASC),
    CONSTRAINT FK_DrivingLicenses_ServiceOrders FOREIGN KEY (OrderID) REFERENCES ServiceOrders (OrderID),
    CONSTRAINT FK_DrivingLicenses_LicenseClasses FOREIGN KEY (LicenseClassID) REFERENCES LicenseClasses (LicenseClassID),
    CONSTRAINT FK_DrivingLicenses_LicenseIssueReasons FOREIGN KEY (IssueReasonID) REFERENCES LicenseIssueReasons (IssueReasonID),
    CONSTRAINT FK_DrivingLicenses_Drivers FOREIGN KEY (DriverID) REFERENCES Drivers (DriverID),
    CONSTRAINT FK_DrivingLicenses_Users FOREIGN KEY (CreatedBy) REFERENCES Users (UserID)
);
GO

-- 2.13 LicenseServiceOrders Table (TPT Subtype of ServiceOrders for Renewals/Replacements)
CREATE TABLE LicenseServiceOrders (
    OrderID INT NOT NULL,
    OldLicenseID INT NOT NULL,
    CONSTRAINT PK_LicenseServiceOrders PRIMARY KEY CLUSTERED (OrderID ASC),
    CONSTRAINT FK_LicenseServiceOrders_ServiceOrders FOREIGN KEY (OrderID) REFERENCES ServiceOrders (OrderID) ON DELETE CASCADE,
    CONSTRAINT FK_LicenseServiceOrders_DrivingLicenses FOREIGN KEY (OldLicenseID) REFERENCES DrivingLicenses (LicenseID)
);
GO

-- 2.14 RetakeTestOrders Table (TPT Subtype of ServiceOrders for Test Retakes)
CREATE TABLE RetakeTestOrders (
    OrderID INT NOT NULL,
    PreviousAppointmentID INT NOT NULL,
    CONSTRAINT PK_RetakeTestOrders PRIMARY KEY CLUSTERED (OrderID ASC),
    CONSTRAINT FK_RetakeTestOrders_ServiceOrders FOREIGN KEY (OrderID) REFERENCES ServiceOrders (OrderID) ON DELETE CASCADE
);
GO

-- 2.15 TestAppointments Table
CREATE TABLE TestAppointments (
    AppointmentID INT IDENTITY(1,1) NOT NULL,
    TestTypeID INT NOT NULL,
    OrderID INT NOT NULL,
    IsLocked BIT NOT NULL CONSTRAINT DF_TestAppointments_IsLocked DEFAULT (0),
    TestFee SMALLMONEY NOT NULL,
    TestDate DATETIME NOT NULL,
    CreatedBy INT NOT NULL,
    RetakeTestOrderID INT NULL,
    CONSTRAINT PK_TestAppointments PRIMARY KEY CLUSTERED (AppointmentID ASC),
    CONSTRAINT FK_TestAppointments_TestTypes FOREIGN KEY (TestTypeID) REFERENCES TestTypes (TestTypeID),
    CONSTRAINT FK_TestAppointments_ServiceOrders FOREIGN KEY (OrderID) REFERENCES ServiceOrders (OrderID),
    CONSTRAINT FK_TestAppointments_Users FOREIGN KEY (CreatedBy) REFERENCES Users (UserID)
);
GO

-- Add Mutual References between TestAppointments and RetakeTestOrders
ALTER TABLE RetakeTestOrders ADD CONSTRAINT FK_RetakeTestOrders_TestAppointments
    FOREIGN KEY (PreviousAppointmentID) REFERENCES TestAppointments (AppointmentID);
GO

ALTER TABLE TestAppointments ADD CONSTRAINT FK_TestAppointments_RetakeTestOrders
    FOREIGN KEY (RetakeTestOrderID) REFERENCES RetakeTestOrders (OrderID);
GO

-- 2.16 Tests Table
CREATE TABLE Tests (
    TestID INT IDENTITY(1,1) NOT NULL,
    TestAppointmentID INT NOT NULL,
    TestResult BIT NOT NULL, -- 1: Pass, 0: Fail
    Notes NVARCHAR(500) NULL,
    CreatedBy INT NOT NULL,
    TestDate DATETIME NOT NULL CONSTRAINT DF_Tests_TestDate DEFAULT (GETDATE()),
    CONSTRAINT PK_Tests PRIMARY KEY CLUSTERED (TestID ASC),
    CONSTRAINT UQ_Tests_TestAppointmentID UNIQUE (TestAppointmentID),
    CONSTRAINT FK_Tests_TestAppointments FOREIGN KEY (TestAppointmentID) REFERENCES TestAppointments (AppointmentID),
    CONSTRAINT FK_Tests_Users FOREIGN KEY (CreatedBy) REFERENCES Users (UserID)
);
GO

-- 2.17 DetainedLicenses Table
CREATE TABLE DetainedLicenses (
    DetainID INT IDENTITY(1,1) NOT NULL,
    LicenseID INT NOT NULL,
    DetainDate DATETIME NOT NULL CONSTRAINT DF_DetainedLicenses_DetainDate DEFAULT (GETDATE()),
    FineFees SMALLMONEY NOT NULL,
    CreatedBy INT NOT NULL,
    ReleasedBy INT NULL,
    IsReleased BIT NOT NULL CONSTRAINT DF_DetainedLicenses_IsReleased DEFAULT (0),
    ReleaseDate DATETIME NULL,
    ReleaseOrderID INT NULL,
    DetainReason NVARCHAR(500) NULL,
    CONSTRAINT PK_DetainedLicenses PRIMARY KEY CLUSTERED (DetainID ASC),
    CONSTRAINT FK_DetainedLicenses_DrivingLicenses FOREIGN KEY (LicenseID) REFERENCES DrivingLicenses (LicenseID),
    CONSTRAINT FK_DetainedLicenses_CreatedByUsers FOREIGN KEY (CreatedBy) REFERENCES Users (UserID),
    CONSTRAINT FK_DetainedLicenses_ReleasedByUsers FOREIGN KEY (ReleasedBy) REFERENCES Users (UserID),
    CONSTRAINT FK_DetainedLicenses_ServiceOrders FOREIGN KEY (ReleaseOrderID) REFERENCES ServiceOrders (OrderID)
);
GO

-- 2.18 InternationalLicenses Table
CREATE TABLE InternationalLicenses (
    InternationalLicenseID INT IDENTITY(1,1) NOT NULL,
    OrderID INT NOT NULL,
    DriverID INT NOT NULL,
    IssuedUsingLocalLicenseID INT NOT NULL,
    IssueDate DATETIME NOT NULL CONSTRAINT DF_InternationalLicenses_IssueDate DEFAULT (GETDATE()),
    ExpirationDate DATETIME NOT NULL,
    IsActive BIT NOT NULL CONSTRAINT DF_InternationalLicenses_IsActive DEFAULT (1),
    CreatedBy INT NOT NULL,
    CONSTRAINT PK_InternationalLicenses PRIMARY KEY CLUSTERED (InternationalLicenseID ASC),
    CONSTRAINT FK_InternationalLicenses_ServiceOrders FOREIGN KEY (OrderID) REFERENCES ServiceOrders (OrderID),
    CONSTRAINT FK_InternationalLicenses_Drivers FOREIGN KEY (DriverID) REFERENCES Drivers (DriverID),
    CONSTRAINT FK_InternationalLicenses_DrivingLicenses FOREIGN KEY (IssuedUsingLocalLicenseID) REFERENCES DrivingLicenses (LicenseID),
    CONSTRAINT FK_InternationalLicenses_Users FOREIGN KEY (CreatedBy) REFERENCES Users (UserID)
);
GO

-- Indexing for High Performance
CREATE NONCLUSTERED INDEX IX_People_NationalID ON People(NationalID);
CREATE NONCLUSTERED INDEX IX_ServiceOrders_PersonID ON ServiceOrders(PersonID);
CREATE NONCLUSTERED INDEX IX_ServiceOrders_OrderStatus ON ServiceOrders(OrderStatus);
CREATE NONCLUSTERED INDEX IX_DrivingLicenses_DriverID ON DrivingLicenses(DriverID);
CREATE NONCLUSTERED INDEX IX_DrivingLicenses_LicenseClassID ON DrivingLicenses(LicenseClassID);
CREATE NONCLUSTERED INDEX IX_TestAppointments_OrderID ON TestAppointments(OrderID);
CREATE NONCLUSTERED INDEX IX_DetainedLicenses_LicenseID ON DetainedLicenses(LicenseID);
GO

-- ============================================================================
-- 3. PROPER LOOKUP DATA (Exact Requirements from DVLD Specification PDF)
-- ============================================================================

-- 3.1 OrderStatuses
SET IDENTITY_INSERT OrderStatuses ON;
INSERT INTO OrderStatuses (OrderStatusID, Status) VALUES
(1, N'New'),
(2, N'Cancelled'),
(3, N'Completed');
SET IDENTITY_INSERT OrderStatuses OFF;
GO

-- 3.2 Services Catalog
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
GO

-- 3.3 LicenseClasses
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
GO

-- 3.4 TestTypes
SET IDENTITY_INSERT TestTypes ON;
INSERT INTO TestTypes (TestTypeID, TestTypeName, Cost, Description) VALUES
(1, N'Vision Test', 10.0000, N'Medical eye examination to verify driver visual acuity and fitness.'),
(2, N'Written (Theory) Test', 20.0000, N'Theoretical exam on road signs, safe driving principles, and traffic laws.'),
(3, N'Practical (Street) Test', 30.0000, N'Field driving examination to assess driver vehicle handling and road safety compliance.');
SET IDENTITY_INSERT TestTypes OFF;
GO

-- 3.5 LicenseIssueReasons
SET IDENTITY_INSERT LicenseIssueReasons ON;
INSERT INTO LicenseIssueReasons (IssueReasonID, ReasonTitle) VALUES
(1, N'First Time'),
(2, N'Renew'),
(3, N'Replacement for Damaged'),
(4, N'Replacement for Lost');
SET IDENTITY_INSERT LicenseIssueReasons OFF;
GO

-- 3.6 Countries (Standard World Countries List)
SET IDENTITY_INSERT Countries ON;
INSERT INTO Countries (CountryID, CountryName) VALUES
(1, N'Afghanistan'),
(2, N'Albania'),
(3, N'Algeria'),
(4, N'Andorra'),
(5, N'Angola'),
(6, N'Antigua and Barbuda'),
(7, N'Argentina'),
(8, N'Armenia'),
(9, N'Australia'),
(10, N'Austria'),
(11, N'Azerbaijan'),
(12, N'Bahamas'),
(13, N'Bahrain'),
(14, N'Bangladesh'),
(15, N'Barbados'),
(16, N'Belarus'),
(17, N'Belgium'),
(18, N'Belize'),
(19, N'Benin'),
(20, N'Bhutan'),
(21, N'Bolivia'),
(22, N'Bosnia and Herzegovina'),
(23, N'Botswana'),
(24, N'Brazil'),
(25, N'Brunei'),
(26, N'Bulgaria'),
(27, N'Burkina Faso'),
(28, N'Burundi'),
(29, N'Cabo Verde'),
(30, N'Cambodia'),
(31, N'Cameroon'),
(32, N'Canada'),
(33, N'Central African Republic'),
(34, N'Chad'),
(35, N'Chile'),
(36, N'China'),
(37, N'Colombia'),
(38, N'Comoros'),
(39, N'Congo'),
(40, N'Costa Rica'),
(41, N'Croatia'),
(42, N'Cuba'),
(43, N'Cyprus'),
(44, N'Czech Republic'),
(45, N'Denmark'),
(46, N'Djibouti'),
(47, N'Dominica'),
(48, N'Dominican Republic'),
(49, N'Ecuador'),
(50, N'Egypt'),
(51, N'El Salvador'),
(52, N'Equatorial Guinea'),
(53, N'Eritrea'),
(54, N'Estonia'),
(55, N'Eswatini'),
(56, N'Ethiopia'),
(57, N'Fiji'),
(58, N'Finland'),
(59, N'France'),
(60, N'Gabon'),
(61, N'Gambia'),
(62, N'Georgia'),
(63, N'Germany'),
(64, N'Ghana'),
(65, N'Greece'),
(66, N'Grenada'),
(67, N'Guatemala'),
(68, N'Guinea'),
(69, N'Guinea-Bissau'),
(70, N'Guyana'),
(71, N'Haiti'),
(72, N'Honduras'),
(73, N'Hungary'),
(74, N'Iceland'),
(75, N'India'),
(76, N'Indonesia'),
(77, N'Iran'),
(78, N'Iraq'),
(79, N'Ireland'),
(80, N'Italy'),
(81, N'Ivory Coast'),
(82, N'Jamaica'),
(83, N'Japan'),
(84, N'Jordan'),
(85, N'Kazakhstan'),
(86, N'Kenya'),
(87, N'Kiribati'),
(88, N'Kuwait'),
(89, N'Kyrgyzstan'),
(90, N'Laos'),
(91, N'Latvia'),
(92, N'Lebanon'),
(93, N'Lesotho'),
(94, N'Liberia'),
(95, N'Libya'),
(96, N'Liechtenstein'),
(97, N'Lithuania'),
(98, N'Luxembourg'),
(99, N'Madagascar'),
(100, N'Malawi'),
(101, N'Malaysia'),
(102, N'Maldives'),
(103, N'Mali'),
(104, N'Malta'),
(105, N'Marshall Islands'),
(106, N'Mauritania'),
(107, N'Mauritius'),
(108, N'Mexico'),
(109, N'Micronesia'),
(110, N'Moldova'),
(111, N'Monaco'),
(112, N'Mongolia'),
(113, N'Montenegro'),
(114, N'Morocco'),
(115, N'Mozambique'),
(116, N'Myanmar'),
(117, N'Namibia'),
(118, N'Nauru'),
(119, N'Nepal'),
(120, N'Netherlands'),
(121, N'New Zealand'),
(122, N'Nicaragua'),
(123, N'Niger'),
(124, N'Nigeria'),
(125, N'North Korea'),
(126, N'North Macedonia'),
(127, N'Norway'),
(128, N'Oman'),
(129, N'Pakistan'),
(130, N'Palau'),
(131, N'Palestine'),
(132, N'Panama'),
(133, N'Papua New Guinea'),
(134, N'Paraguay'),
(135, N'Peru'),
(136, N'Philippines'),
(137, N'Poland'),
(138, N'Portugal'),
(139, N'Qatar'),
(140, N'Romania'),
(141, N'Russia'),
(142, N'Rwanda'),
(143, N'Saint Kitts and Nevis'),
(144, N'Saint Lucia'),
(145, N'Saint Vincent and the Grenadines'),
(146, N'Samoa'),
(147, N'San Marino'),
(148, N'Sao Tome and Principe'),
(149, N'Saudi Arabia'),
(150, N'Senegal'),
(151, N'Serbia'),
(152, N'Seychelles'),
(153, N'Sierra Leone'),
(154, N'Singapore'),
(155, N'Slovakia'),
(156, N'Slovenia'),
(157, N'Solomon Islands'),
(158, N'Somalia'),
(159, N'South Africa'),
(160, N'South Korea'),
(161, N'South Sudan'),
(162, N'Spain'),
(163, N'Sri Lanka'),
(164, N'Sudan'),
(165, N'Suriname'),
(166, N'Sweden'),
(167, N'Switzerland'),
(168, N'Syria'),
(169, N'Taiwan'),
(170, N'Tajikistan'),
(171, N'Tanzania'),
(172, N'Thailand'),
(173, N'Timor-Leste'),
(174, N'Togo'),
(175, N'Tonga'),
(176, N'Trinidad and Tobago'),
(177, N'Tunisia'),
(178, N'Turkey'),
(179, N'Turkmenistan'),
(180, N'Tuvalu'),
(181, N'Uganda'),
(182, N'Ukraine'),
(183, N'United Arab Emirates'),
(184, N'United Kingdom'),
(185, N'United States'),
(186, N'Uruguay'),
(187, N'Uzbekistan'),
(188, N'Vanuatu'),
(189, N'Vatican City'),
(190, N'Venezuela'),
(191, N'Vietnam'),
(192, N'Yemen'),
(193, N'Zambia'),
(194, N'Zimbabwe');
SET IDENTITY_INSERT Countries OFF;
GO

-- ============================================================================
-- 4. OPERATIONAL AND SAMPLE DATA (Rich, Consistent, Relational Dataset)
-- ============================================================================

-- 4.1 People (Master Profile Records)
SET IDENTITY_INSERT People ON;
INSERT INTO People (PersonID, NationalID, FirstName, SecondName, ThirdName, LastName, BirthDate, Gender, Address, Phone, Email, NationalityCountryID, ImagePath) VALUES
(1, N'N1001', N'Omar', N'Khaled', N'Ahmad', N'Al-Masri', '1990-05-14', 0, N'Wasfi Al-Tal St, Amman', N'+962791112233', N'omar.masri@licensehub.jo', 84, N'C:\DVLD\Images\omar.jpg'),
(2, N'N1002', N'Fatima', N'Zahra', N'Mahmoud', N'Khatib', '1988-11-20', 1, N'University St, Irbid', N'+962782223344', N'fatima.khatib@licensehub.jo', 84, N'C:\DVLD\Images\fatima.jpg'),
(3, N'N1003', N'Yousef', N'Ibrahim', N'Hassan', N'Tarawneh', '1995-03-22', 0, N'Al-Madina Al-Monawara St, Amman', N'+962773334455', N'yousef.t@licensehub.jo', 84, N'C:\DVLD\Images\yousef.jpg'),
(4, N'N1004', N'Rania', N'Sami', N'Tareq', N'Majali', '1992-09-08', 1, N'King Abdullah II St, Zarqa', N'+962794445566', N'rania.majali@licensehub.jo', 84, N'C:\DVLD\Images\rania.jpg'),
(5, N'N1005', N'Ahmad', N'Saleh', N'Mustafa', N'Qudah', '1985-07-19', 0, N'Yarmouk Highway, Jerash', N'+962785556677', N'ahmad.qudah@licensehub.jo', 84, N'C:\DVLD\Images\ahmad.jpg'),
(6, N'N1006', N'Lina', N'Marwan', N'Jamal', N'Nsour', '1997-12-04', 1, N'As-Salt Historic Center, Salt', N'+962776667788', N'lina.nsour@licensehub.jo', 84, N'C:\DVLD\Images\lina.jpg'),
(7, N'N1007', N'Tariq', N'Ziad', N'Faris', N'Hadidi', '1993-01-30', 0, N'Mecca St, Amman', N'+962797778899', N'tariq.hadidi@gmail.com', 84, NULL),
(8, N'N1008', N'Huda', N'Munir', N'Bassem', N'Abbadi', '1996-06-17', 1, N'Queen Rania St, Amman', N'+962788889900', N'huda.abbadi@gmail.com', 84, NULL),
(9, N'N1009', N'Kareem', N'Nasser', N'Suleiman', N'Dweik', '1991-04-11', 0, N'Zahran St, 7th Circle, Amman', N'+962779990011', N'kareem.dweik@yahoo.com', 84, NULL),
(10, N'N1010', N'Sarah', N'Adnan', N'Fouad', N'Jabari', '2000-08-25', 1, N'Baghdad St, Zarqa', N'+962790001122', N'sarah.jabari@hotmail.com', 84, NULL),
(11, N'N1011', N'Hamza', N'Bilal', N'Rashid', N'Shawish', '2002-10-15', 0, N'Palestine St, Irbid', N'+962781113355', N'hamza.s@gmail.com', 84, NULL),
(12, N'N1012', N'Nour', N'Hassan', N'Salem', N'Ghanem', '1994-02-18', 1, N'Corniche St, Aqaba', N'+962772224466', N'nour.ghanem@gmail.com', 84, NULL),
(13, N'N1013', N'Mahmoud', N'Akram', N'Hussein', N'Obeidat', '1987-11-05', 0, N'Bani Kinanah, Irbid', N'+962793335577', N'mahmoud.obeidat@gmail.com', 84, NULL),
(14, N'N1014', N'Mona', N'Raed', N'Nabil', N'Zubi', '1999-07-29', 1, N'Prince Hassan St, Madaba', N'+962784446688', N'mona.zubi@yahoo.com', 84, NULL),
(15, N'N1015', N'Fadi', N'Waleed', N'Samir', N'Rawashdeh', '1998-03-12', 0, N'Al-Karak Fortress Rd, Karak', N'+962775557799', N'fadi.rawashdeh@gmail.com', 84, NULL),
(16, N'N1016', N'Dina', N'Emad', N'Kamel', N'Barakat', '2001-05-20', 1, N'Gardens St, Amman', N'+962796668800', N'dina.barakat@gmail.com', 84, NULL),
(17, N'N1017', N'Rami', N'Ayman', N'Tayseer', N'Husseini', '1989-12-14', 0, N'Old City, Jerusalem Rd, Ramallah', N'+970599112233', N'rami.husseini@palnet.com', 131, NULL),
(18, N'N1018', N'Layla', N'Osama', N'Salim', N'Tamimi', '1995-09-03', 1, N'Ain Sara St, Hebron', N'+970598223344', N'layla.tamimi@gmail.com', 131, NULL),
(19, N'N1019', N'Fahad', N'Sultan', N'Saud', N'Al-Otaibi', '1992-06-21', 0, N'King Fahd Rd, Riyadh', N'+966501112233', N'fahad.otaibi@saudi.com', 149, NULL),
(20, N'N1020', N'Reem', N'Abdullah', N'Mubarak', N'Al-Dosari', '1996-01-19', 1, N'Corniche, Khobar', N'+966552223344', N'reem.dosari@yahoo.com', 149, NULL),
(21, N'N1021', N'Mustafa', N'Sherif', N'Farouk', N'El-Sayed', '1986-04-10', 0, N'Tahrir Square, Cairo', N'+201011223344', N'mustafa.elsayed@egypt.com', 50, NULL),
(22, N'N1022', N'Aya', N'Hossam', N'Gamal', N'Mansour', '1997-10-31', 1, N'Alexandria Corniche, Alexandria', N'+201222334455', N'aya.mansour@gmail.com', 50, NULL),
(23, N'N1023', N'Rashid', N'Saeed', N'Humaid', N'Al-Nuaimi', '1990-08-16', 0, N'Sheikh Zayed Rd, Dubai', N'+971501112233', N'rashid.nuaimi@uae.gov', 175, NULL),
(24, N'N1024', N'John', N'Robert', N'Michael', N'Smith', '1984-03-05', 0, N'742 Evergreen Terrace, Springfield', N'+12025550143', N'john.smith@gmail.com', 177, NULL),
(25, N'N1025', N'Emily', N'David', N'Grace', N'Johnson', '1993-11-28', 1, N'221B Baker Street, London', N'+447911123456', N'emily.johnson@ukmail.co.uk', 176, NULL);
SET IDENTITY_INSERT People OFF;
GO

-- 4.2 Users (Administrative & Operational Personnel)
SET IDENTITY_INSERT Users ON;
INSERT INTO Users (UserID, PersonID, UserName, Password, IsActive, Permissions) VALUES
(1, 1, N'admin', N'admin123', 1, -1),             -- Full Administrator
(2, 2, N'fatima.k', N'fatima123', 1, -1),         -- Licensing Supervisor
(3, 3, N'yousef.t', N'yousef123', 1, 15),         -- Applications & Registration Officer
(4, 4, N'rania.m', N'rania123', 1, 31),           -- Senior Examiner & Inspector
(5, 5, N'ahmad.q', N'ahmad123', 1, 7),            -- Testing Appointment Coordinator
(6, 6, N'lina.n', N'lina123', 1, 63);             -- Detained License & Fine Manager
SET IDENTITY_INSERT Users OFF;
GO

-- 4.3 Drivers (Registered Official Drivers)
SET IDENTITY_INSERT Drivers ON;
INSERT INTO Drivers (DriverID, PersonID, CreatedBy, CreatedDate) VALUES
(1, 7, 1, '2023-01-15 10:30:00'),
(2, 8, 2, '2023-02-10 11:15:00'),
(3, 9, 3, '2023-03-05 09:45:00'),
(4, 10, 4, '2023-04-12 14:20:00'),
(5, 11, 1, '2023-05-18 08:30:00'),
(6, 12, 2, '2023-06-22 13:10:00'),
(7, 13, 3, '2023-07-08 16:40:00'),
(8, 14, 4, '2023-08-14 10:00:00'),
(9, 15, 1, '2023-09-01 11:30:00'),
(10, 19, 2, '2023-10-19 15:00:00');
SET IDENTITY_INSERT Drivers OFF;
GO

-- 4.4 ServiceOrders (Master Application Records)
SET IDENTITY_INSERT ServiceOrders ON;
INSERT INTO ServiceOrders (OrderID, ServiceID, PersonID, OrderDate, OrderStatus, LastStatusDate, OrderFee, CreatedBy) VALUES
-- Orders 1-10: First-time Local Driving License Orders (Completed, yielded licenses)
(1, 1, 7, '2023-01-02 09:00:00', 3, '2023-01-15 10:30:00', 15.0000, 1),
(2, 1, 8, '2023-01-20 10:15:00', 3, '2023-02-10 11:15:00', 15.0000, 2),
(3, 1, 9, '2023-02-15 08:30:00', 3, '2023-03-05 09:45:00', 15.0000, 3),
(4, 1, 10, '2023-03-10 11:00:00', 3, '2023-04-12 14:20:00', 15.0000, 4),
(5, 1, 11, '2023-04-05 09:30:00', 3, '2023-05-18 08:30:00', 15.0000, 1),
(6, 1, 12, '2023-05-12 14:00:00', 3, '2023-06-22 13:10:00', 15.0000, 2),
(7, 1, 13, '2023-06-01 10:45:00', 3, '2023-07-08 16:40:00', 15.0000, 3),
(8, 1, 14, '2023-07-02 12:20:00', 3, '2023-08-14 10:00:00', 15.0000, 4),
(9, 1, 15, '2023-08-10 09:15:00', 3, '2023-09-01 11:30:00', 15.0000, 1),
(10, 1, 19, '2023-09-15 13:40:00', 3, '2023-10-19 15:00:00', 15.0000, 2),

-- Orders 11-13: Retake Test Orders (ServiceID = 7)
(11, 7, 9, '2023-02-25 11:00:00', 3, '2023-02-25 11:00:00', 5.0000, 3),
(12, 7, 11, '2023-04-20 14:30:00', 3, '2023-04-20 14:30:00', 5.0000, 1),
(13, 7, 14, '2023-07-22 10:15:00', 3, '2023-07-22 10:15:00', 5.0000, 4),

-- Orders 14-16: Lifecycle License Services (Renew, Replace Lost, Replace Damaged)
(14, 2, 7, '2024-01-10 09:30:00', 3, '2024-01-10 10:00:00', 10.0000, 1), -- Renew License
(15, 3, 8, '2024-02-14 11:20:00', 3, '2024-02-14 12:00:00', 20.0000, 2), -- Replace Lost
(16, 4, 10, '2024-03-01 14:10:00', 3, '2024-03-01 14:45:00', 20.0000, 3), -- Replace Damaged

-- Orders 17-18: Release Detained License Orders (ServiceID = 5)
(17, 5, 9, '2024-04-05 15:30:00', 3, '2024-04-05 15:45:00', 15.0000, 6),
(18, 5, 13, '2024-05-10 11:00:00', 3, '2024-05-10 11:30:00', 15.0000, 6),

-- Orders 19-21: International License Orders (ServiceID = 6)
(19, 6, 7, '2024-02-01 10:00:00', 3, '2024-02-01 10:30:00', 20.0000, 1),
(20, 6, 12, '2024-03-15 11:30:00', 3, '2024-03-15 12:00:00', 20.0000, 2),
(21, 6, 19, '2024-04-20 14:00:00', 3, '2024-04-20 14:30:00', 20.0000, 3),

-- Orders 22-26: Ongoing / In-Progress and Cancelled New License Orders
(22, 1, 16, '2024-06-01 09:00:00', 1, '2024-06-01 09:00:00', 15.0000, 3), -- In-Progress (At Theory Stage)
(23, 1, 17, '2024-06-05 10:15:00', 1, '2024-06-05 10:15:00', 15.0000, 4), -- In-Progress (At Practical Stage)
(24, 1, 18, '2024-06-10 11:30:00', 1, '2024-06-10 11:30:00', 15.0000, 1), -- In-Progress (At Vision Stage)
(25, 1, 20, '2024-06-12 14:00:00', 2, '2024-06-15 10:00:00', 15.0000, 2), -- Cancelled by applicant
(26, 1, 21, '2024-06-18 15:45:00', 1, '2024-06-18 15:45:00', 15.0000, 3); -- Newly Submitted
SET IDENTITY_INSERT ServiceOrders OFF;
GO

-- 4.5 NewLicenseOrders (TPT Subtype Linking to LicenseClasses)
INSERT INTO NewLicenseOrders (OrderID, LicenseClassID) VALUES
(1, 3),  -- Ordinary Driving License (Car)
(2, 3),  -- Ordinary Driving License (Car)
(3, 1),  -- Small Motorcycle
(4, 3),  -- Ordinary Driving License (Car)
(5, 2),  -- Heavy Motorcycle
(6, 3),  -- Ordinary Driving License (Car)
(7, 4),  -- Commercial (Taxi/Limo)
(8, 3),  -- Ordinary Driving License (Car)
(9, 5),  -- Agricultural
(10, 7), -- Truck and Heavy Vehicle
(22, 3), -- Ordinary Driving License
(23, 3), -- Ordinary Driving License
(24, 1), -- Small Motorcycle
(25, 3), -- Cancelled Application
(26, 6); -- Small and Medium Bus
GO

-- 4.6 DrivingLicenses (Local Driving Licenses Issued)
SET IDENTITY_INSERT DrivingLicenses ON;
INSERT INTO DrivingLicenses (LicenseID, OrderID, LicenseClassID, IssueDate, ExpirationDate, IssueReasonID, DriverID, Notes, CreatedBy, IsActive, Cost) VALUES
-- Historical / Original licenses issued upon passing tests
(1, 1, 3, '2023-01-15 10:30:00', '2033-01-15 10:30:00', 1, 1, N'First time issuance. No medical restrictions.', 1, 0, 20.0000), -- Replaced by renewal #11
(2, 2, 3, '2023-02-10 11:15:00', '2033-02-10 11:15:00', 1, 2, N'Driver must wear corrective lenses.', 2, 0, 20.0000),      -- Deactivated (Lost, replaced by #12)
(3, 3, 1, '2023-03-05 09:45:00', '2028-03-05 09:45:00', 1, 3, N'Small motorcycle standard license.', 3, 1, 15.0000),
(4, 4, 3, '2023-04-12 14:20:00', '2033-04-12 14:20:00', 1, 4, N'Standard vehicle license.', 4, 0, 20.0000),                    -- Deactivated (Damaged, replaced by #13)
(5, 5, 2, '2023-05-18 08:30:00', '2028-05-18 08:30:00', 1, 5, N'Heavy motorcycle certified.', 1, 1, 30.0000),
(6, 6, 3, '2023-06-22 13:10:00', '2033-06-22 13:10:00', 1, 6, N'Clean driving record.', 2, 1, 20.0000),
(7, 7, 4, '2023-07-08 16:40:00', '2033-07-08 16:40:00', 1, 7, N'Commercial public transport endorsement.', 3, 1, 200.0000),
(8, 8, 3, '2023-08-14 10:00:00', '2033-08-14 10:00:00', 1, 8, N'Valid for passenger cars.', 4, 1, 20.0000),
(9, 9, 5, '2023-09-01 11:30:00', '2033-09-01 11:30:00', 1, 9, N'Agricultural machinery and tractors.', 1, 1, 50.0000),
(10, 10, 7, '2023-10-19 15:00:00', '2033-10-19 15:00:00', 1, 10, N'Heavy cargo and truck transport license.', 2, 1, 300.0000),

-- Newly Issued Licenses through Lifecycle Services
(11, 14, 3, '2024-01-10 10:00:00', '2034-01-10 10:00:00', 2, 1, N'Renewed driving license.', 1, 1, 20.0000),
(12, 15, 3, '2024-02-14 12:00:00', '2033-02-10 11:15:00', 4, 2, N'Replacement for lost license.', 2, 1, 20.0000),
(13, 16, 3, '2024-03-01 14:45:00', '2033-04-12 14:20:00', 3, 4, N'Replacement for damaged license.', 3, 1, 20.0000);
SET IDENTITY_INSERT DrivingLicenses OFF;
GO

-- 4.7 LicenseServiceOrders (TPT Subtype Linking to Replaced Licenses)
INSERT INTO LicenseServiceOrders (OrderID, OldLicenseID) VALUES
(14, 1), -- Renew Order 14 replaced License 1
(15, 2), -- Replace Lost Order 15 replaced License 2
(16, 4); -- Replace Damaged Order 16 replaced License 4
GO

-- 4.8 TestAppointments (Scheduled Test Slots)
SET IDENTITY_INSERT TestAppointments ON;
INSERT INTO TestAppointments (AppointmentID, TestTypeID, OrderID, IsLocked, TestFee, TestDate, CreatedBy, RetakeTestOrderID) VALUES
-- Applicant 7 (Order 1): Passed Vision, Theory, Street sequentially
(1, 1, 1, 1, 10.0000, '2023-01-05 09:00:00', 1, NULL),
(2, 2, 1, 1, 20.0000, '2023-01-10 10:00:00', 1, NULL),
(3, 3, 1, 1, 30.0000, '2023-01-15 09:30:00', 1, NULL),

-- Applicant 8 (Order 2): Passed Vision, Theory, Street
(4, 1, 2, 1, 10.0000, '2023-01-25 11:00:00', 2, NULL),
(5, 2, 2, 1, 20.0000, '2023-02-02 10:30:00', 2, NULL),
(6, 3, 2, 1, 30.0000, '2023-02-10 10:00:00', 2, NULL),

-- Applicant 9 (Order 3): Failed Vision once (Appt 7), retook (Appt 8 via Order 11), then passed Theory & Street
(7, 1, 3, 1, 10.0000, '2023-02-20 09:00:00', 3, NULL),  -- Failed
(8, 1, 3, 1, 10.0000, '2023-02-26 09:30:00', 3, NULL),  -- Retake Appt (RetakeTestOrderID updated below)
(9, 2, 3, 1, 20.0000, '2023-03-01 11:00:00', 3, NULL),
(10, 3, 3, 1, 30.0000, '2023-03-05 09:00:00', 3, NULL),

-- Applicant 10 (Order 4): Passed Vision, Theory, Street
(11, 1, 4, 1, 10.0000, '2023-03-15 10:00:00', 4, NULL),
(12, 2, 4, 1, 20.0000, '2023-03-25 11:30:00', 4, NULL),
(13, 3, 4, 1, 30.0000, '2023-04-12 13:00:00', 4, NULL),

-- Applicant 11 (Order 5): Passed Vision, Failed Theory (Appt 15), Retook Theory (Appt 16 via Order 12), Passed Street
(14, 1, 5, 1, 10.0000, '2023-04-10 09:00:00', 1, NULL),
(15, 2, 5, 1, 20.0000, '2023-04-18 10:30:00', 1, NULL), -- Failed
(16, 2, 5, 1, 20.0000, '2023-04-25 11:00:00', 1, NULL), -- Retake Appt (RetakeTestOrderID updated below)
(17, 3, 5, 1, 30.0000, '2023-05-18 08:00:00', 1, NULL),

-- In-Progress Applicants (Orders 22, 23, 24)
(18, 1, 22, 1, 10.0000, '2024-06-03 09:00:00', 5, NULL), -- Passed Vision
(19, 2, 22, 0, 20.0000, '2026-10-15 10:00:00', 5, NULL), -- Scheduled Theory (Upcoming, Unlocked)
(20, 1, 23, 1, 10.0000, '2024-06-07 10:00:00', 5, NULL), -- Passed Vision
(21, 2, 23, 1, 20.0000, '2024-06-14 11:00:00', 5, NULL), -- Passed Theory
(22, 3, 23, 0, 30.0000, '2026-10-20 09:00:00', 5, NULL), -- Scheduled Street (Upcoming, Unlocked)
(23, 1, 24, 0, 10.0000, '2026-10-10 09:30:00', 5, NULL); -- Scheduled Vision (Upcoming, Unlocked)
SET IDENTITY_INSERT TestAppointments OFF;
GO

-- 4.9 RetakeTestOrders (TPT Subtype Linking to Previous Failed Appointments)
INSERT INTO RetakeTestOrders (OrderID, PreviousAppointmentID) VALUES
(11, 7),  -- Retake order 11 booked due to failed Vision appointment 7
(12, 15); -- Retake order 12 booked due to failed Theory appointment 15
GO

-- Update TestAppointments with RetakeTestOrderID now that RetakeTestOrders exist
UPDATE TestAppointments SET RetakeTestOrderID = 11 WHERE AppointmentID = 8;
UPDATE TestAppointments SET RetakeTestOrderID = 12 WHERE AppointmentID = 16;
GO

-- 4.10 Tests (Exam Results & Evaluation Records)
SET IDENTITY_INSERT Tests ON;
INSERT INTO Tests (TestID, TestAppointmentID, TestResult, Notes, CreatedBy, TestDate) VALUES
(1, 1, 1, N'Vision 6/6 bilateral without corrective glasses.', 4, '2023-01-05 09:20:00'),
(2, 2, 1, N'Theory score: 96/100. Excellent road signs comprehension.', 4, '2023-01-10 10:35:00'),
(3, 3, 1, N'Street test passed smoothly. Safe lane changing and parking.', 4, '2023-01-15 10:15:00'),
(4, 4, 1, N'Vision 6/6 with corrective lenses.', 4, '2023-01-25 11:20:00'),
(5, 5, 1, N'Theory score: 90/100. Passed.', 4, '2023-02-02 11:00:00'),
(6, 6, 1, N'Practical driving test passed.', 4, '2023-02-10 10:45:00'),
(7, 7, 0, N'Failed vision acuity test (left eye 6/18). Advised optometrist consultation.', 4, '2023-02-20 09:15:00'),
(8, 8, 1, N'Vision corrected with glasses. Acuity verified 6/6.', 4, '2023-02-26 09:45:00'),
(9, 9, 1, N'Theory score: 88/100. Passed.', 4, '2023-03-01 11:30:00'),
(10, 10, 1, N'Practical exam passed on motorcycle track.', 4, '2023-03-05 09:30:00'),
(11, 11, 1, N'Vision test passed.', 4, '2023-03-15 10:20:00'),
(12, 12, 1, N'Theory score: 92/100. Passed.', 4, '2023-03-25 12:00:00'),
(13, 13, 1, N'Practical road exam passed.', 4, '2023-04-12 13:45:00'),
(14, 14, 1, N'Vision test passed.', 4, '2023-04-10 09:15:00'),
(15, 15, 0, N'Theory score: 58/100. Failed on priority and right-of-way section.', 4, '2023-04-18 10:50:00'),
(16, 16, 1, N'Theory retake score: 94/100. Passed.', 4, '2023-04-25 11:25:00'),
(17, 17, 1, N'Practical road exam passed.', 4, '2023-05-18 08:30:00'),
(18, 18, 1, N'Vision test passed successfully.', 4, '2024-06-03 09:15:00'),
(19, 20, 1, N'Vision test passed successfully.', 4, '2024-06-07 10:20:00'),
(20, 21, 1, N'Theory score: 86/100. Passed.', 4, '2024-06-14 11:30:00');
SET IDENTITY_INSERT Tests OFF;
GO

-- 4.11 DetainedLicenses (Suspension & Impoundment Records)
SET IDENTITY_INSERT DetainedLicenses ON;
INSERT INTO DetainedLicenses (DetainID, LicenseID, DetainDate, FineFees, CreatedBy, ReleasedBy, IsReleased, ReleaseDate, ReleaseOrderID, DetainReason) VALUES
-- Released Record
(1, 3, '2024-03-20 14:00:00', 100.0000, 6, 6, 1, '2024-04-05 15:45:00', 17, N'Exceeding posted speed limit by more than 30 km/h in urban zone.'),
-- Active (Still Detained) Records
(2, 7, '2024-05-02 08:30:00', 250.0000, 6, NULL, 0, NULL, NULL, N'Operating commercial taxi vehicle without mandatory safety permit.'),
(3, 10, '2024-05-25 16:15:00', 350.0000, 6, NULL, 0, NULL, NULL, N'Gross overload of commercial transport cargo exceeding axle weight threshold.');
SET IDENTITY_INSERT DetainedLicenses OFF;
GO

-- 4.12 InternationalLicenses (Permits Issued to Local Class 3 License Holders)
SET IDENTITY_INSERT InternationalLicenses ON;
INSERT INTO InternationalLicenses (InternationalLicenseID, OrderID, DriverID, IssuedUsingLocalLicenseID, IssueDate, ExpirationDate, IsActive, CreatedBy) VALUES
(1, 19, 1, 11, '2024-02-01 10:30:00', '2025-02-01 10:30:00', 1, 1),
(2, 20, 6, 6,  '2024-03-15 12:00:00', '2025-03-15 12:00:00', 1, 2);
SET IDENTITY_INSERT InternationalLicenses OFF;
GO

-- ============================================================================
-- 5. USEFUL BUSINESS VIEWS FOR SSMS QUERYING & UI INTEGRATION
-- ============================================================================

-- 5.1 Local Driving License Applications Full View
CREATE VIEW vw_LocalDrivingLicenseApplications AS
SELECT 
    NLO.OrderID AS LocalDrivingLicenseApplicationID,
    SO.OrderID,
    LC.ClassName,
    P.NationalID,
    (P.FirstName + N' ' + P.SecondName + N' ' + ISNULL(P.ThirdName + N' ', N'') + P.LastName) AS FullName,
    SO.OrderDate,
    (
        SELECT COUNT(DISTINCT TA.TestTypeID)
        FROM TestAppointments TA
        INNER JOIN Tests T ON TA.AppointmentID = T.TestAppointmentID
        WHERE TA.OrderID = SO.OrderID AND T.TestResult = 1
    ) AS PassedTestCount,
    OS.Status AS OrderStatus
FROM NewLicenseOrders NLO
INNER JOIN ServiceOrders SO ON NLO.OrderID = SO.OrderID
INNER JOIN LicenseClasses LC ON NLO.LicenseClassID = LC.LicenseClassID
INNER JOIN People P ON SO.PersonID = P.PersonID
INNER JOIN OrderStatuses OS ON SO.OrderStatus = OS.OrderStatusID;
GO

-- 5.2 Driving Licenses View
CREATE VIEW vw_DrivingLicenses AS
SELECT 
    L.LicenseID,
    L.OrderID,
    D.DriverID,
    P.NationalID,
    (P.FirstName + N' ' + P.SecondName + N' ' + ISNULL(P.ThirdName + N' ', N'') + P.LastName) AS FullName,
    LC.ClassName,
    L.IssueDate,
    L.ExpirationDate,
    LIR.ReasonTitle AS IssueReason,
    L.IsActive,
    CASE 
        WHEN EXISTS (SELECT 1 FROM DetainedLicenses DL WHERE DL.LicenseID = L.LicenseID AND DL.IsReleased = 0) THEN 1 
        ELSE 0 
    END AS IsDetained,
    L.Cost
FROM DrivingLicenses L
INNER JOIN LicenseClasses LC ON L.LicenseClassID = LC.LicenseClassID
INNER JOIN LicenseIssueReasons LIR ON L.IssueReasonID = LIR.IssueReasonID
INNER JOIN Drivers D ON L.DriverID = D.DriverID
INNER JOIN People P ON D.PersonID = P.PersonID;
GO

-- 5.3 International Licenses View
CREATE VIEW vw_InternationalLicenses AS
SELECT 
    IL.InternationalLicenseID,
    IL.OrderID,
    IL.DriverID,
    P.NationalID,
    (P.FirstName + N' ' + P.SecondName + N' ' + ISNULL(P.ThirdName + N' ', N'') + P.LastName) AS FullName,
    IL.IssuedUsingLocalLicenseID,
    IL.IssueDate,
    IL.ExpirationDate,
    IL.IsActive
FROM InternationalLicenses IL
INNER JOIN Drivers D ON IL.DriverID = D.DriverID
INNER JOIN People P ON D.PersonID = P.PersonID;
GO

-- 5.4 Detained Licenses View
CREATE VIEW vw_DetainedLicenses AS
SELECT 
    DL.DetainID,
    DL.LicenseID,
    DL.DetainDate,
    DL.FineFees,
    DL.IsReleased,
    DL.ReleaseDate,
    P.NationalID,
    (P.FirstName + N' ' + P.SecondName + N' ' + ISNULL(P.ThirdName + N' ', N'') + P.LastName) AS FullName,
    DL.ReleaseOrderID,
    DL.DetainReason
FROM DetainedLicenses DL
INNER JOIN DrivingLicenses L ON DL.LicenseID = L.LicenseID
INNER JOIN Drivers D ON L.DriverID = D.DriverID
INNER JOIN People P ON D.PersonID = P.PersonID;
GO

-- 5.5 Test Appointments Detailed View
CREATE VIEW vw_TestAppointments AS
SELECT 
    TA.AppointmentID,
    TA.OrderID,
    TT.TestTypeName,
    LC.ClassName,
    TA.TestDate,
    TA.TestFee,
    TA.IsLocked,
    T.TestResult,
    T.Notes AS ExaminerNotes,
    TA.RetakeTestOrderID
FROM TestAppointments TA
INNER JOIN TestTypes TT ON TA.TestTypeID = TT.TestTypeID
INNER JOIN ServiceOrders SO ON TA.OrderID = SO.OrderID
LEFT JOIN NewLicenseOrders NLO ON SO.OrderID = NLO.OrderID
LEFT JOIN LicenseClasses LC ON NLO.LicenseClassID = LC.LicenseClassID
LEFT JOIN Tests T ON TA.AppointmentID = T.TestAppointmentID;
GO

-- 5.6 Drivers View
CREATE VIEW vw_Drivers AS
SELECT 
    D.DriverID,
    D.PersonID,
    P.NationalID,
    (P.FirstName + N' ' + P.SecondName + N' ' + ISNULL(P.ThirdName + N' ', N'') + P.LastName) AS FullName,
    D.CreatedDate,
    (SELECT COUNT(*) FROM DrivingLicenses DL WHERE DL.DriverID = D.DriverID AND DL.IsActive = 1) AS ActiveLicenses
FROM Drivers D
INNER JOIN People P ON D.PersonID = P.PersonID;
GO

-- 5.7 Users View
CREATE VIEW vw_Users AS
SELECT 
    U.UserID,
    U.PersonID,
    (P.FirstName + N' ' + P.SecondName + N' ' + ISNULL(P.ThirdName + N' ', N'') + P.LastName) AS FullName,
    U.UserName,
    U.IsActive,
    U.Permissions
FROM Users U
INNER JOIN People P ON U.PersonID = P.PersonID;
GO

PRINT '================================================================================';
PRINT '  DVLD Database script executed successfully!';
PRINT '  All 18 tables, relationships, PDF lookup data, and sample records created.';
PRINT '================================================================================';
GO
