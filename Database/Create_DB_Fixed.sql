USE [master];
GO
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'ELearning_DB')
BEGIN
    CREATE DATABASE [ELearning_DB];
END
GO
