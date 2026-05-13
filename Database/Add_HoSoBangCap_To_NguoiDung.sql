-- Add HoSoBangCap column for Instructor Validation
-- This script adds a NULL NVARCHAR(MAX) column if it does not already exist.
IF COL_LENGTH('dbo.NguoiDung', 'HoSoBangCap') IS NULL
BEGIN
    ALTER TABLE dbo.NguoiDung
    ADD HoSoBangCap NVARCHAR(MAX) NULL;
    PRINT 'Added HoSoBangCap column to dbo.NguoiDung';
END
ELSE
BEGIN
    PRINT 'Column HoSoBangCap already exists on dbo.NguoiDung';
END
