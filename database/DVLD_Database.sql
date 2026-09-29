CREATE DATABASE DVLD;
GO

USE DVLD;
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
(1, 'New'),
(2, 'Cancelled'),
(3, 'Completed');
SET IDENTITY_INSERT OrderStatuses OFF;

SET IDENTITY_INSERT Services ON;
INSERT INTO Services (ServiceID, ServiceName, Cost) VALUES
(1, 'New Local Driving License Service', 15.0000),
(2, 'Renew Driving License Service', 10.0000),
(3, 'Replacement for a Lost Driving License Service', 20.0000),
(4, 'Replacement for a Damaged Driving License Service', 20.0000),
(5, 'Release Detained Driving License Service', 15.0000),
(6, 'New International License Service', 20.0000),
(7, 'Retake Test Service', 5.0000);
SET IDENTITY_INSERT Services OFF;

SET IDENTITY_INSERT LicenseClasses ON;
INSERT INTO LicenseClasses (LicenseClassID, ClassName, ClassDescription, MinimumAllowedAge, ValidityLength, ClassFees) VALUES
(1, 'Class 1 - Small Motorcycle', 'Allows the driver to drive small motorcycles with limited capacity and power.', 18, 5, 15.0000),
(2, 'Class 2 - Heavy Motorcycle License', 'Allows the driver to drive large and heavy motorcycles.', 21, 5, 30.0000),
(3, 'Class 3 - Ordinary driving license', 'Allows the driver to drive personal vehicles and light vehicles.', 18, 10, 20.0000),
(4, 'Class 4 - Commercial', 'Allows the driver to drive taxi and limousine vehicles.', 21, 10, 200.0000),
(5, 'Class 5 - Agricultural', 'Allows the driver to drive tractors and agricultural machinery.', 21, 10, 50.0000),
(6, 'Class 6 - Small and medium bus', 'Allows the driver to drive small and medium-sized buses.', 21, 10, 250.0000),
(7, 'Class 7 - Truck and heavy vehicle', 'Allows the driver to drive large trucks and heavy transport vehicles.', 21, 10, 300.0000);
SET IDENTITY_INSERT LicenseClasses OFF;

SET IDENTITY_INSERT TestTypes ON;
INSERT INTO TestTypes (TestTypeID, TestTypeName, Cost, Description) VALUES
(1, 'Vision Test', 10.0000, 'Medical eye examination to verify driver visual acuity and fitness.'),
(2, 'Written (Theory) Test', 20.0000, 'Theoretical exam on road signs, safe driving principles, and traffic laws.'),
(3, 'Practical (Street) Test', 30.0000, 'Field driving examination to assess driver vehicle handling and road safety compliance.');
SET IDENTITY_INSERT TestTypes OFF;

SET IDENTITY_INSERT LicenseIssueReasons ON;
INSERT INTO LicenseIssueReasons (IssueReasonID, ReasonTitle) VALUES
(1, 'First Time'),
(2, 'Renew'),
(3, 'Replacement for Damaged'),
(4, 'Replacement for Lost');
SET IDENTITY_INSERT LicenseIssueReasons OFF;

SET IDENTITY_INSERT Countries ON;
INSERT INTO Countries (CountryID, CountryName) VALUES
(1, 'Jordan'), (2, 'Palestine'), (3, 'Saudi Arabia'), (4, 'Egypt'), (5, 'United Arab Emirates'),
(6, 'Kuwait'), (7, 'Qatar'), (8, 'Bahrain'), (9, 'Oman'), (10, 'Lebanon'),
(11, 'Syria'), (12, 'Iraq'), (13, 'Morocco'), (14, 'Tunisia'), (15, 'Algeria'),
(16, 'United States'), (17, 'United Kingdom'), (18, 'Canada'), (19, 'Germany'), (20, 'France');
SET IDENTITY_INSERT Countries OFF;
GO

-- ============================================================================
-- 3. DML: SAMPLE OPERATIONAL DATA
-- ============================================================================

SET IDENTITY_INSERT People ON;
INSERT INTO People (PersonID, NationalID, FirstName, SecondName, ThirdName, LastName, BirthDate, Gender, Address, Phone, Email, NationalityCountryID, ImagePath) VALUES
(1, 'N1001', 'Omar', 'Khaled', 'Ahmad', 'Al-Masri', '1990-05-14', 0, 'Wasfi Al-Tal St, Amman', '+962791112233', 'omar.masri@licensehub.jo', 1, NULL),
(2, 'N1002', 'Fatima', 'Zahra', 'Mahmoud', 'Khatib', '1988-11-20', 1, 'University St, Irbid', '+962782223344', 'fatima.khatib@licensehub.jo', 1, NULL),
(3, 'N1003', 'Yousef', 'Ibrahim', 'Hassan', 'Tarawneh', '1995-03-22', 0, 'Al-Madina Al-Monawara St, Amman', '+962773334455', 'yousef.t@licensehub.jo', 1, NULL),
(4, 'N1004', 'Rania', 'Sami', 'Tareq', 'Majali', '1992-09-08', 1, 'King Abdullah II St, Zarqa', '+962794445566', 'rania.majali@licensehub.jo', 1, NULL),
(5, 'N1005', 'Ahmad', 'Saleh', 'Mustafa', 'Qudah', '1985-07-19', 0, 'Yarmouk Highway, Jerash', '+962785556677', 'ahmad.qudah@licensehub.jo', 1, NULL),
(6, 'N1006', 'Tariq', 'Ziad', 'Faris', 'Hadidi', '1993-01-30', 0, 'Mecca St, Amman', '+962797778899', 'tariq.hadidi@gmail.com', 1, NULL),
(7, 'N1007', 'Huda', 'Munir', 'Bassem', 'Abbadi', '1996-06-17', 1, 'Queen Rania St, Amman', '+962788889900', 'huda.abbadi@gmail.com', 1, NULL),
(8, 'N1008', 'Kareem', 'Nasser', 'Suleiman', 'Dweik', '1991-04-11', 0, 'Zahran St, Amman', '+962779990011', 'kareem.dweik@yahoo.com', 1, NULL),
(9, 'N1009', 'Sarah', 'Adnan', 'Fouad', 'Jabari', '2000-08-25', 1, 'Baghdad St, Zarqa', '+962790001122', 'sarah.jabari@hotmail.com', 1, NULL),
(10, 'N1010', 'Hamza', 'Bilal', 'Rashid', 'Shawish', '2002-10-15', 0, 'Palestine St, Irbid', '+962781113355', 'hamza.s@gmail.com', 1, NULL),
(11, 'N1011', 'Dina', 'Emad', 'Kamel', 'Barakat', '2001-05-20', 1, 'Gardens St, Amman', '+962796668800', 'dina.barakat@gmail.com', 1, NULL),
(12, 'N1012', 'Rami', 'Ayman', 'Tayseer', 'Husseini', '1989-12-14', 0, 'Main St, Ramallah', '+970599112233', 'rami.husseini@palnet.com', 2, NULL);
SET IDENTITY_INSERT People OFF;

SET IDENTITY_INSERT Users ON;
INSERT INTO Users (UserID, PersonID, UserName, Password, IsActive, Permissions) VALUES
(1, 1, 'admin', 'admin123', 1, -1),
(2, 2, 'fatima.k', 'fatima123', 1, -1),
(3, 3, 'yousef.t', 'yousef123', 1, 15);
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
(1, 1, 3, '2023-01-15 10:30:00', '2033-01-15 10:30:00', 1, 1, 'First time issuance.', 1, 0, 20.0000), -- Renewed by #6
(2, 2, 3, '2023-02-10 11:15:00', '2033-02-10 11:15:00', 1, 2, 'Corrective lenses required.', 2, 0, 20.0000), -- Replaced by #7
(3, 3, 1, '2023-03-05 09:45:00', '2028-03-05 09:45:00', 1, 3, 'Small motorcycle.', 3, 1, 15.0000),
(4, 4, 3, '2023-04-12 14:20:00', '2033-04-12 14:20:00', 1, 4, 'Standard vehicle license.', 1, 1, 20.0000),
(5, 5, 2, '2023-05-18 08:30:00', '2028-05-18 08:30:00', 1, 5, 'Heavy motorcycle certified.', 2, 1, 30.0000),
(6, 7, 3, '2024-01-10 10:00:00', '2034-01-10 10:00:00', 2, 1, 'Renewed driving license.', 1, 1, 20.0000),
(7, 8, 3, '2024-02-14 12:00:00', '2033-02-10 11:15:00', 4, 2, 'Replacement for lost license.', 2, 1, 20.0000);
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
(1, 1, 1, 'Vision passed.', 1, '2023-01-05 09:20:00'),
(2, 2, 1, 'Theory score: 96/100.', 1, '2023-01-10 10:35:00'),
(3, 3, 1, 'Practical exam passed.', 1, '2023-01-15 10:15:00'),
(4, 4, 0, 'Failed vision acuity.', 3, '2023-02-20 09:15:00'),
(5, 5, 1, 'Vision passed with glasses.', 3, '2023-02-26 09:45:00'),
(6, 6, 1, 'Theory score: 88/100.', 3, '2023-03-01 11:30:00'),
(7, 7, 1, 'Practical exam passed.', 3, '2023-03-05 09:30:00'),
(8, 8, 1, 'Vision passed.', 3, '2024-06-03 09:15:00');
SET IDENTITY_INSERT Tests OFF;

SET IDENTITY_INSERT DetainedLicenses ON;
INSERT INTO DetainedLicenses (DetainID, LicenseID, DetainDate, FineFees, CreatedBy, ReleasedBy, IsReleased, ReleaseDate, ReleaseOrderID, DetainReason) VALUES
(1, 3, '2024-03-20 14:00:00', 100.0000, 1, 1, 1, '2024-04-05 15:45:00', 9, 'Exceeding speed limit.'),
(2, 4, '2024-05-02 08:30:00', 250.0000, 1, NULL, 0, NULL, NULL, 'Driving without safety permit.');
SET IDENTITY_INSERT DetainedLicenses OFF;

SET IDENTITY_INSERT InternationalLicenses ON;
INSERT INTO InternationalLicenses (InternationalLicenseID, OrderID, DriverID, IssuedUsingLocalLicenseID, IssueDate, ExpirationDate, IsActive, CreatedBy) VALUES
(1, 10, 1, 6, '2024-02-01 10:30:00', '2025-02-01 10:30:00', 1, 1);
SET IDENTITY_INSERT InternationalLicenses OFF;
GO
