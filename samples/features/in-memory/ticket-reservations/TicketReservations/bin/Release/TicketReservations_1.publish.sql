﻿/*
Deployment script for TicketReservations

This code was generated by a tool.
Changes to this file may cause incorrect behavior and will be lost if
the code is regenerated.
*/

GO
SET ANSI_NULLS, ANSI_PADDING, ANSI_WARNINGS, ARITHABORT, CONCAT_NULL_YIELDS_NULL, QUOTED_IDENTIFIER ON;

SET NUMERIC_ROUNDABORT OFF;


GO
:setvar DatabaseName "TicketReservations"
:setvar DefaultFilePrefix "TicketReservations"
:setvar DefaultDataPath "C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\DATA\"
:setvar DefaultLogPath "C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\DATA\"

GO
:on error exit
GO
/*
Detect SQLCMD mode and disable script execution if SQLCMD mode is not supported.
To re-enable the script after enabling SQLCMD mode, execute the following:
SET NOEXEC OFF; 
*/
:setvar __IsSqlCmdEnabled "True"
GO
IF N'$(__IsSqlCmdEnabled)' NOT LIKE N'True'
    BEGIN
        PRINT N'SQLCMD mode must be enabled to successfully execute this script.';
        SET NOEXEC ON;
    END


GO
USE [$(DatabaseName)];


GO
PRINT N'Dropping [dbo].[InsertReservationDetails]...';


GO
DROP PROCEDURE [dbo].[InsertReservationDetails];


GO
PRINT N'Creating [dbo].[TicketReservationDetail]...';


GO
CREATE TABLE [dbo].[TicketReservationDetail] (
    [TicketReservationID]       BIGINT          NOT NULL,
    [TicketReservationDetailID] BIGINT          IDENTITY (1, 1) NOT NULL,
    [Quantity]                  INT             NOT NULL,
    [FlightID]                  INT             NOT NULL,
    [Comment]                   NVARCHAR (1000) NULL,
    CONSTRAINT [PK_TicketReservationDetail] PRIMARY KEY NONCLUSTERED ([TicketReservationDetailID] ASC)
)
WITH (MEMORY_OPTIMIZED = ON);


GO
PRINT N'Creating [dbo].[InsertReservationDetails]...';


GO
/*
CREATE PROCEDURE InsertReservationDetails(@TicketReservationID int, @LineCount int, @Comment NVARCHAR(1000), @FlightID int)
AS
BEGIN
	DECLARE @loop int = 0;
	WHILE (@loop < @LineCount)
	BEGIN
		INSERT INTO dbo.TicketReservationDetail (TicketReservationID, Quantity, FlightID, Comment) 
			VALUES(@TicketReservationID, @loop % 8 + 1, @FlightID, @Comment);
		SET @loop += 1;
	END
END
*/


-- natively compiled version of the stored procedure:
CREATE PROCEDURE InsertReservationDetails(@TicketReservationID int, @LineCount int, @Comment NVARCHAR(1000), @FlightID int)
WITH NATIVE_COMPILATION, SCHEMABINDING
as
BEGIN ATOMIC WITH (TRANSACTION ISOLATION LEVEL=SNAPSHOT, LANGUAGE=N'English')


	DECLARE @loop int = 0;
	while (@loop < @LineCount)
	BEGIN
		INSERT INTO dbo.TicketReservationDetail (TicketReservationID, Quantity, FlightID, Comment) 
		    VALUES(@TicketReservationID, @loop % 8 + 1, @FlightID, @Comment);
		SET @loop += 1;
	END
END
GO
PRINT N'Altering [dbo].[ReadMultipleReservations]...';


GO
ALTER PROCEDURE ReadMultipleReservations(@ServerTransactions int, @RowsPerTransaction int, @ThreadID int)
AS
BEGIN 
	DECLARE @tranCount int = 0;
	DECLARE @CurrentSeq int = 0;
	DECLARE @Sum int = 0;
	DECLARE @loop int = 0;
	WHILE (@tranCount < @ServerTransactions)	
	BEGIN
		BEGIN TRY
			SELECT @CurrentSeq = RAND() * IDENT_CURRENT(N'dbo.TicketReservationDetail')
			SET @loop = 0
			BEGIN TRAN
			WHILE (@loop < @RowsPerTransaction)
			BEGIN
				SELECT @Sum += FlightID from dbo.TicketReservationDetail where TicketReservationDetailID = @CurrentSeq - @loop;
				SET @loop += 1;
			END
			COMMIT TRAN
		END TRY
		BEGIN CATCH
			IF XACT_STATE() = -1
				ROLLBACK TRAN
			;THROW
		END CATCH
		SET @tranCount += 1;
	END
END
GO
PRINT N'Altering [dbo].[BatchInsertReservations]...';


GO
-- helper stored procedure to 

ALTER PROCEDURE BatchInsertReservations(@ServerTransactions int, @RowsPerTransaction int, @ThreadID int)
AS
BEGIN
	DECLARE @tranCount int = 0;
	DECLARE @TS Datetime2;
	DECLARE @Char_TS NVARCHAR(23);
	DECLARE @CurrentSeq int = 0;

	SET @TS = SYSDATETIME();
	SET @Char_TS = CAST(@TS AS NVARCHAR(23));
	WHILE (@tranCount < @ServerTransactions)	
	BEGIN
		BEGIN TRY
			BEGIN TRAN
			SET @CurrentSeq = NEXT VALUE FOR TicketReservationSequence ;
			EXEC InsertReservationDetails  @CurrentSeq, @RowsPerTransaction, @Char_TS, @ThreadID;
			COMMIT TRAN
		END TRY
		BEGIN CATCH
			IF XACT_STATE() = -1
				ROLLBACK TRAN
			;THROW
		END CATCH
		SET @tranCount += 1;
	END
END
GO
PRINT N'Update complete.';


GO
