-- Add IsDeleted column for soft-delete support
-- This script adds a NOT NULL BIT column with default 0 if it does not already exist.
IF COL_LENGTH('dbo.KhoaHoc', 'IsDeleted') IS NULL
BEGIN
    ALTER TABLE dbo.KhoaHoc
    ADD IsDeleted BIT NOT NULL CONSTRAINT DF_KhoaHoc_IsDeleted DEFAULT 0;
    PRINT 'Added IsDeleted column to dbo.KhoaHoc';
END
ELSE
BEGIN
    PRINT 'Column IsDeleted already exists on dbo.KhoaHoc';
END
