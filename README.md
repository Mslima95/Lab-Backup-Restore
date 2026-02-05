# Lab-Backup-Restore

# SQL Server – Backup & Restore | Portfólio DBA

Este repositório demonstra cenários reais de recuperação de desastres no SQL Server,
utilizados no dia a dia de um DBA.

## 🛠 Ambiente
- SQL Server 2022 Developer Edition (16.x)
- Recovery Model: FULL
- Sistema Operacional: Windows

## 🔬 LABs

### LAB 01 – Erro Humano / Bug de Aplicação
**Cenário**
- Atualização indevida em tabela crítica

**Solução**
- Restore Full
- Restore sequencial de Backups de Log
- Validação dos dados

📄 Script: `labs/01_erro_humano_restore_full_log.sql`

---

### LAB 02 – Page Restore
**Cenário**
- Corrupção física de página de dados

**Solução**
- Identificação via DBCC CHECKDB
- Page Restore
- Restore de Logs
- Backup de Log pós-recovery

📄 Script: `labs/02_page_restore.sql`

## 🎯 Objetivo do Projeto
Demonstrar domínio de estratégias de backup, restore e recuperação de desastres
no SQL Server, com foco em boas práticas de administração de banco de dados.

## 📌 Observações
- Scripts utilizados apenas para fins educacionais
- DBCC WRITEPAGE executado em ambiente de laboratório controlado
