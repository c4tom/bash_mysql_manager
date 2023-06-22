# Array contendo todos os privilégios disponíveis
# Array contendo todos os privilégios disponíveis
PRIVILEGIOS=(
    "ALL PRIVILEGES"               # Todos os privilégios possíveis
    "ALTER"                        # Permite alterar a estrutura de tabelas existentes
    "ALTER ROUTINE"                # Permite alterar rotinas existentes
    "CREATE"                       # Permite criar novos bancos de dados e tabelas
    "CREATE ROLE"                  # Permite criar novos papéis de usuário
    "CREATE ROUTINE"               # Permite criar rotinas (procedimentos armazenados e funções)
    "CREATE TABLESPACE"            # Permite criar tablespaces
    "CREATE TEMPORARY TABLES"      # Permite criar tabelas temporárias
    "CREATE USER"                  # Permite criar novos usuários
    "CREATE VIEW"                  # Permite criar novas views
    "DELETE"                       # Permite excluir registros de tabelas
    "DROP"                         # Permite excluir bancos de dados e tabelas
    "DROP ROLE"                    # Permite excluir papéis de usuário
    "EVENT"                        # Permite criar, alterar e excluir eventos
    "EXECUTE"                      # Permite executar procedimentos armazenados e funções
    "FILE"                         # Permite acessar arquivos no servidor
    "GRANT ANY ROLE"               # Permite conceder qualquer papel de usuário a outros usuários
    "GRANT OPTION"                 # Permite conceder privilégios a outros usuários
    "INDEX"                        # Permite criar índices em tabelas
    "INSERT"                       # Permite inserir novos registros em tabelas
    "LOCK TABLES"                  # Permite bloquear tabelas para uso exclusivo
    "PROCESS"                      # Permite visualizar e matar processos de outros usuários
    "REFERENCES"                   # Permite criar chaves estrangeiras em tabelas
    "RELOAD"                       # Permite recarregar configurações do servidor
    "REPLICATION CLIENT"           # Permite acessar informações sobre a replicação
    "REPLICATION SLAVE"            # Permite atuar como um slave em uma replicação de banco de dados
    "SELECT"                       # Permite realizar consultas (seleção) nos dados
    "SHOW DATABASES"               # Permite visualizar os bancos de dados disponíveis
    "SHOW VIEW"                    # Permite visualizar a definição de views
    "SUPER"                        # Permite executar comandos com privilégios de superusuário
    "SHUTDOWN"                     # Permite desligar o servidor do banco de dados
    "TRIGGER"                      # Permite criar, alterar e excluir gatilhos
    "UPDATE"                       # Permite atualizar registros existentes em tabelas
)


# Loop para percorrer os privilégios e imprimir com comentários
for ((i=0; i<${#PRIVILEGIOS[@]}; i++))
do
    # Acessando o privilégio atual através do índice "i" no array "PRIVILEGIOS"
    PRIVILEGIO="${PRIVILEGIOS[i]}"
    echo $PRIVILEGIO;
done