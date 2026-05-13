USE [ELearning_DB];
GO

EXEC sp_msforeachtable "ALTER TABLE ? NOCHECK CONSTRAINT all"
GO

EXEC sp_MSForEachTable "DELETE FROM ?"
GO

EXEC sp_msforeachtable "ALTER TABLE ? WITH CHECK CHECK CONSTRAINT all"
GO
