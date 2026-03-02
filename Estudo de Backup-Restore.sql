/****************************************************************************************
 Projeto : Portfólio DBA – Backup e Restore SQL Server
 Autor   : [KMatheus Sobreira Lima]
 Banco   : Teste_Desastre
 Objetivo: Demonstração de cenários de recuperação de desastres no SQL Server
           - Backup Full e Log automatizados
           - Erro humano / bug de aplicação
           - Restore Full + Log
           - Page Restore (corrupção de página)
 Versão  : SQL Server 2022 Developer Edition (16.x)
****************************************************************************************/


/****************************************************************************************
 JOBS DE BACKUP AUTOMATIZADOS
 Objetivo: Demonstrar backup Full e Log via SQL Server Agent
****************************************************************************************/

-- ================================
-- Job: Backup Full - Job_BackupFull_Desastre
-- Frequência: Diário (ex: 02:00)
-- Objetivo: Backup completo da base Teste_Desastre
-- ================================

BACKUP DATABASE Teste_Desastre
TO DISK = 'C:\Teste_Desastre_Bckp\Teste_FULL.bak'
WITH COMPRESSION, INIT, STATS = 10;
GO

-- ================================
-- Job: Backup Log - Job_BackupLog_Desastre
-- Frequência: A cada 5 minutos
-- Objetivo: Backup do log de transações da base Teste_Desastre
-- ================================

DECLARE @BackupLogPath NVARCHAR(255);

SET @BackupLogPath = 'C:\Teste_Desastre_Bckp\Teste_LOG_' 
    + CONVERT(VARCHAR(8), GETDATE(), 112)  -- YYYYMMDD
    + '_' 
    + REPLACE(CONVERT(VARCHAR(8), GETDATE(), 108), ':', '')  -- HHMMSS
    + '.trn';

BACKUP LOG Teste_Desastre
TO DISK = @BackupLogPath
WITH COMPRESSION, STATS = 10;
GO

/****************************************************************************************
 LAB 01 – ERRO HUMANO / BUG DE APLICAÇÃO
****************************************************************************************/

USE Teste_Desastre;
GO

-- Simulação de erro humano / bug de aplicação
UPDATE Funcionario
SET Salario = 1;
GO


/****************************************************************************************
 Colocando o banco em SINGLE_USER para restore
****************************************************************************************/
USE master;
GO

ALTER DATABASE Teste_Desastre
SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
GO


/****************************************************************************************
 Restore FULL (Base permanece em NORECOVERY para aplicação dos logs)
****************************************************************************************/
RESTORE DATABASE Teste_Desastre
FROM DISK = 'C:\Teste_Desastre_Bckp\Teste_FULL.bak'
WITH 
    NORECOVERY,
    REPLACE,
    STATS = 10;
GO


/****************************************************************************************
 Restore LOG
****************************************************************************************/
RESTORE LOG Teste_Desastre
FROM DISK = 'C:\Teste_Desastre_Bckp\Teste_LOG_20260204_201004.trn'
WITH NORECOVERY;
GO

RESTORE LOG Teste_Desastre
FROM DISK = 'C:\Teste_Desastre_Bckp\Teste_LOG_20260204_201206.trn'
WITH NORECOVERY;
GO

RESTORE LOG Teste_Desastre
FROM DISK = 'C:\Teste_Desastre_Bckp\Teste_LOG_20260204_201404.trn'
WITH RECOVERY;
GO


/****************************************************************************************
 Retornando o banco para MULTI_USER
****************************************************************************************/
ALTER DATABASE Teste_Desastre
SET MULTI_USER WITH ROLLBACK IMMEDIATE;
GO


-- Validação dos dados após restore
USE Teste_Desastre;
GO

SELECT *
FROM Funcionario;
GO



/****************************************************************************************
 LAB 02 – PAGE RESTORE (CORRUPÇÃO DE PÁGINA)
****************************************************************************************/

DBCC IND ('Teste_Desastre', 'PageRestoreTest', -1);
GO

ALTER DATABASE Teste_Desastre
SET MULTI_USER WITH ROLLBACK IMMEDIATE;
GO

ALTER DATABASE Teste_Desastre
SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
GO

USE master;
GO

DBCC WRITEPAGE
(
    'Teste_Desastre',
    1,        -- File ID
    603,      -- Page ID
    0,        -- Offset
    2,        -- Length
    0x0000,   -- Valor escrito
    1
);
GO

ALTER DATABASE Teste_Desastre
SET MULTI_USER;
GO

DBCC CHECKDB ('Teste_Desastre')
WITH NO_INFOMSGS, ALL_ERRORMSGS;
GO

SELECT  
    DB_NAME(susp.database_id)                         AS DatabaseName,
    OBJECT_SCHEMA_NAME(ind.object_id, ind.database_id) AS ObjectSchemaName,
    OBJECT_NAME(ind.object_id, ind.database_id)        AS ObjectName,
    susp.*
FROM msdb.dbo.suspect_pages susp
CROSS APPLY sys.dm_db_database_page_allocations
(
    susp.database_id, NULL, NULL, NULL, NULL
) ind
WHERE ind.allocated_page_file_id = susp.file_id
  AND ind.allocated_page_page_id = susp.page_id;
GO

SELECT *
FROM msdb.dbo.suspect_pages
ORDER BY last_update_date DESC;
GO

RESTORE DATABASE Teste_Desastre
PAGE = '1:603'
FROM DISK = 'C:\Teste_Desastre_Bckp\Teste_FULL.bak'
WITH NORECOVERY;
GO

RESTORE LOG Teste_Desastre
FROM DISK = 'C:\Teste_Desastre_Bckp\Teste_LOG_20260204_201004.trn'
WITH NORECOVERY;
GO

RESTORE LOG Teste_Desastre
FROM DISK = 'C:\Teste_Desastre_Bckp\Teste_LOG_20260204_201206.trn'
WITH NORECOVERY;
GO

RESTORE LOG Teste_Desastre
FROM DISK = 'C:\Teste_Desastre_Bckp\Teste_LOG_20260204_201404.trn'
WITH NORECOVERY;
GO

RESTORE LOG Teste_Desastre
FROM DISK = 'C:\Teste_Desastre_Bckp\Teste_LOG_20260204_202049.trn'
WITH RECOVERY;
GO

RESTORE LOG Teste_Desastre
FROM DISK = 'C:\Teste_Desastre_Bckp\Teste_LOG_20260204_202404.trn'
WITH RECOVERY;
GO

DBCC CHECKDB('Teste_Desastre');
GO

SELECT name, recovery_model_desc
FROM sys.databases
WHERE name = 'Teste_Desastre';
GO

USE Teste_Desastre;
GO

SELECT *
FROM PageRestoreTest;
GO
