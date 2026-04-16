/****************************************************************************************
 Projeto : Portfólio DBA – Backup e Restore SQL Server
 Autor   : [KMatheus Sobreira Lima]
 Banco   : Teste_Desastre
 Objetivo: Demonstração de cenários de recuperação de desastres no SQL Server
           - Erro humano / bug de aplicação
           - Restore Full + Log
           - Page Restore (corrupção de página)
 Versão  : SQL Server 2022 Developer Edition (16.x)
****************************************************************************************/


/****************************************************************************************
 LAB 01 – ERRO HUMANO / BUG DE APLICAÇÃO
 Cenário:
   - Atualização indevida em tabela crítica
   - Recuperação via Backup Full + sequência de Backups de Log
****************************************************************************************/

USE Teste_Desastre;
GO

-- Simulação de erro humano / bug de aplicação

UPDATE Funcionario
SET Nome = 'Errados', Salario = 1;
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
FROM DISK = 'C:\Teste_Desastre_Bckp\BCKPS_FULL\Teste_FULL_20260415_214102.bak'
WITH 
    NORECOVERY,
    REPLACE,
    STATS = 10;
GO


/****************************************************************************************
 Restore LOG
 Observações:
   - Sempre iniciar com um Backup FULL
   - Respeitar rigorosamente a sequência dos Backups de Log
****************************************************************************************/
RESTORE LOG Teste_Desastre
FROM DISK = 'C:\Teste_Desastre_Bckp\BCKPS_LOG\Teste_LOG_20260415_214125.trn'
WITH NORECOVERY;
GO


RESTORE LOG Teste_Desastre
FROM DISK = 'C:\Teste_Desastre_Bckp\BCKPS_LOG\Teste_LOG_20260415_214349.trn'
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
FROM Funcionario
GO



/****************************************************************************************
 LAB 02 – PAGE RESTORE (CORRUPÇÃO DE PÁGINA)
 Sequência:
   1. Backup Full
   2. Backup Log
   3. Corrupção da página
   4. Identificação da corrupção
   5. Page Restore
   6. Restore dos Logs
   7. Backup Log pós-restore
****************************************************************************************/


/****************************************************************************************
 Localizando páginas e IDs
****************************************************************************************/
DBCC IND ('Teste_Desastre', 'PageRestoreTest', -1);
GO


/****************************************************************************************
 Alterando estado do banco
****************************************************************************************/
ALTER DATABASE Teste_Desastre
SET MULTI_USER WITH ROLLBACK IMMEDIATE;
GO

ALTER DATABASE Teste_Desastre
SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
GO


/****************************************************************************************
 Corrompendo página manualmente (LAB controlado)
****************************************************************************************/
USE master;
GO

DBCC WRITEPAGE
(
    'Teste_Desastre',
    1,        -- File ID
    604,      -- Page ID
    0,        -- Offset
    2,        -- Length
    0x0000,   -- Valor escrito
    1
);
GO


ALTER DATABASE Teste_Desastre
SET MULTI_USER;
GO


/****************************************************************************************
 Validação de corrupção
****************************************************************************************/
DBCC CHECKDB ('Teste_Desastre')
WITH NO_INFOMSGS, ALL_ERRORMSGS;
GO


/****************************************************************************************
 Identificando objeto afetado pela página corrompida
****************************************************************************************/
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
  AND ind.allocated_page_page_id = susp.page_id
  AND last_update_date >= '2026-03-07 08:00:00' AND last_update_date <= '2026-03-07 20:37:00'
GO



/****************************************************************************************
 Comprovando páginas suspeitas
****************************************************************************************/
SELECT *
FROM msdb.dbo.suspect_pages
ORDER BY last_update_date DESC;
GO


/****************************************************************************************
 PAGE RESTORE
****************************************************************************************/
RESTORE DATABASE Teste_Desastre
PAGE = '1:604'
FROM DISK = 'C:\Teste_Desastre_Bckp\BCKPS_FULL\Teste_FULL_20260415_214102.bak'
WITH NORECOVERY;
GO


/****************************************************************************************
 Restore dos Logs após Page Restore
****************************************************************************************/
RESTORE LOG Teste_Desastre
FROM DISK = 'C:\Teste_Desastre_Bckp\BCKPS_LOG\Teste_LOG_20260415_214125.trn'
WITH NORECOVERY;
GO


RESTORE LOG Teste_Desastre
FROM DISK = 'C:\Teste_Desastre_Bckp\BCKPS_LOG\Teste_LOG_20260415_214349.trn'
WITH RECOVERY;
GO


/****************************************************************************************
 Restore do Backup de Log pós Page Restore
****************************************************************************************/
RESTORE LOG Teste_Desastre
FROM DISK = 'C:\Teste_Desastre_Bckp\BCKPS_LOG\Teste_LOG_20260415_214349.trn'
WITH RECOVERY;
GO



/****************************************************************************************
 Validações finais
****************************************************************************************/
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
