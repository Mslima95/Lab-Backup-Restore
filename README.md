# Lab-Backup-Restore

# SQL Server – Backup & Restore | Portfólio DBA

Este repositório demonstra cenários reais de recuperação de desastres no SQL Server,
utilizados no dia a dia de um DBA. O objetivo é mostrar o fluxo correto de proteção e
recuperação de dados.

## 🛠 Ambiente
- SQL Server 2022 Developer Edition (16.x)
- Recovery Model: FULL
- Sistema Operacional: Windows

## 🔬 LABs

### Pré-requisito
Antes de qualquer teste de erro ou page restore, é realizado:
1. **Backup FULL** da base de dados `Teste_Desastre`.
2. **Backup do Log de transações** em intervalos regulares (ex.: a cada 5 minutos).

Isso garante que qualquer teste ou simulação de desastre possa ser recuperado de forma consistente.

### LAB 01 – Erro Humano / Bug de Aplicação
**Cenário**
- Atualização indevida em tabela crítica

**Solução**
- Restore Full
- Restore sequencial de Backups de Log
- Validação dos dados

📄 Script: `labs/Estudo de Backup-Restore.sql`

---

### LAB 02 – Page Restore
**Cenário**
- Corrupção física de página de dados

**Solução**
- Identificação via DBCC CHECKDB
- Page Restore
- Restore de Logs
- Backup de Log pós-recovery

📄 Script: `Lab-Backup-Restore/02_page_restore.sql`

## 🎯 Objetivo do Projeto
Demonstrar domínio de estratégias de backup, restore e recuperação de desastres
no SQL Server, com foco em boas práticas de administração de banco de dados.
A sequência de backups (Full + Log) antes dos testes reforça a importância de políticas
de proteção e integridade dos dados.

## 📌 Observações
- Scripts utilizados apenas para fins educacionais.
- DBCC WRITEPAGE executado em ambiente de laboratório controlado.
- Backups de Log criam arquivos únicos com timestamp para histórico de transações.
- Backups devem ser realizados **antes de qualquer simulação de erro ou teste de corrupção**.
