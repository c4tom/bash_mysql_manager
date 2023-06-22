gerar um exemplo de um script bash com as seguintes caracteristicas

# Menu com todas as categorias

1 - Configuração
  - Ler arquivo diferente de ARQUIVO_INI, se o usuario escolher outro arquivo, memorizar para que use em todos outros lugares que for solicitar o arquivo ini

2 - Selecionar banco de dados (listar todos os banco de dados e mostra como menu numerado, e solicitar usuario escolher um deles, e memorizar, em DB_SELECTED, para que seja usado em todos outros lugares, e imprimir no topo antes de todos menus)

3 - Banco de Dados (se nao houve escolhido nenhum banco de dados no item 2, mostre todos banco de dados, e solicite escolher 1, e use a Função para mostrar as propriedades do banco de dados e variáveis show_database_properties())
- Criar banco de dados (ao criar o banco de dados memorizar em DB_SELECTED, solicitar o charset que terá este banco, o padrao é: utf8mb4 e o collate: utf8_unicode_ci)
- Gerenciamento de Tabelas
  - Se DB_SELECTED for vazio, solicite-o conforme item 2 e depois mostrar as opções deste submenu:
    - Checar (Deve solicitar ao usuario escolher qualquer ou todos: DB_CHECK_ITEMS)
    - Analisar 
    - Checksum (Deve solicitar ao usuario escolher qualquer ou todos: DB_CHECK_SUM)
    - Otimizar 
    - Reparar (Deve solicitar ao usuario escolher qualquer ou todos: DB_REPAIR)

4 - Backup / Restauração
  - backup fisico
  - backup logico
5 - Status e Monitoramento
  - Lista de processos (atualização a cada 1 segundo)
6 - Gerenciamento de Usuarios
  - Listar todos usuarios
  - Adicionar usuario, (use $HOST_DEFAULT inicialmente, mas solicite outro; gere uma senha com a funcao generate_password, tamanho 15 e segundo parametro LUNS; liste todos os banco de dados e solicite qual será da permissao que será dado ao usuario, use PERMISSOES_DEFAULT, mas solicite outro, imprima PERMISSOES_DISPONIVEIS para o usuario ver quais opções poderá usar
  - Alterar senha (listar todos usuario, e mostrar como um menu numerados, e solicite escolher qual será usado para trocar a senha; a regra da senha é a mesma que foi usada para adicionar o usuario)
  - Alterar permissao ao banco (listar todos os banco de dados como um menu numerado, solicite escolher um item; depois de escolhido, mostre os usuario que tem permissao a este banco, mostre como um menu, se não houver nenhum usuario diferente de root, que tenha permissão a este banco, imprima, nenhum usuario com permissao ao banco e solicite se quer adicionar um usuario (se esta opção for escolhida, usa a mesma logica, que foi usada para adicionar usuario), e volte para o menu de listagem de banco de dados)

7 - Gerenciamento de Replicação
8 - Buscar texto no Banco
  - Se DB_SELECTED for vazio, solicite conforme a logica do item 2, e depois solicite o texto a ser pesquisado


# Globalmente, o script terá
- funcao que imprima os comandos executados, se tiver modo debug TRUE

use as variaveis globais

ARQUIVO_INI=/root/.myini # contem host, user, password

HOST_DEFAULT='%'

PERMISSOES_DEFAULT='SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, ALTER, LOCK TABLES'

PERMISSOES_DISPONIVEIS="ALL PRIVILEGES, CREATE, DROP, SELECT, INSERT, UPDATE, DELETE, GRANT OPTION, ALTER, INDEX, CREATE TEMPORARY TABLES, LOCK TABLES, EXECUTE, SHOW VIEW, EVENT, TRIGGER"

BACKUP_DIR=/dados/backup

ECHO_CMD=false # se for true, todos os comandos deve ser impresso na tela e depois executado

DB_SELECTED= # sera usado para memorizar o banco de dados selecionado


- A funcao generate_password() deve ter 2 parametros:
  1) tamanho da senha 
  2) LUNS (L=lower case, U=uppercase, N=numero, S=caracteres especiais)

