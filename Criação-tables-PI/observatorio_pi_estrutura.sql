-- =============================================================================
--  OBSERVATÓRIO DE PROJETOS INTEGRADORES – SENAC ADS
--  Banco de Dados: SQLite
--  Descrição: Modelo Lógico – Criação das tabelas, índices, triggers e views
-- =============================================================================

PRAGMA foreign_keys = ON;
PRAGMA journal_mode = WAL;

-- =============================================================================
--  TABELAS
-- =============================================================================

CREATE TABLE IF NOT EXISTS turmas (
    id_turma    INTEGER PRIMARY KEY AUTOINCREMENT,
    nome_turma  TEXT    NOT NULL,
    turno       TEXT    NOT NULL
                CHECK (turno IN ('MATUTINO', 'VESPERTINO', 'NOTURNO')),
    ano         INTEGER NOT NULL,
    ativo       INTEGER NOT NULL DEFAULT 1,
    criado_em   TEXT    NOT NULL DEFAULT (datetime('now', 'localtime'))
);

CREATE TABLE IF NOT EXISTS usuarios (
    id_usuario  INTEGER PRIMARY KEY AUTOINCREMENT,
    nome        TEXT    NOT NULL,
    email       TEXT    NOT NULL UNIQUE,
    senha       TEXT    NOT NULL,
    perfil      TEXT    NOT NULL
                CHECK (perfil IN ('ALUNO', 'PROFESSOR', 'COORDENADOR', 'EMPRESA')),
    id_turma    INTEGER,
    ativo       INTEGER NOT NULL DEFAULT 1,
    criado_em   TEXT    NOT NULL DEFAULT (datetime('now', 'localtime')),
    FOREIGN KEY (id_turma) REFERENCES turmas(id_turma)
                ON DELETE SET NULL ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS projetos (
    id_projeto    INTEGER PRIMARY KEY AUTOINCREMENT,
    titulo        TEXT    NOT NULL,
    descricao     TEXT,
    status        TEXT    NOT NULL DEFAULT 'RASCUNHO'
                  CHECK (status IN ('RASCUNHO', 'SUBMETIDO', 'EM_AVALIACAO',
                                    'AVALIADO', 'APROVADO', 'REPROVADO')),
    versao        INTEGER NOT NULL DEFAULT 1,
    id_turma      INTEGER NOT NULL,
    criado_em     TEXT    NOT NULL DEFAULT (datetime('now', 'localtime')),
    atualizado_em TEXT    NOT NULL DEFAULT (datetime('now', 'localtime')),
    FOREIGN KEY (id_turma) REFERENCES turmas(id_turma)
                ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS membros_projeto (
    id            INTEGER PRIMARY KEY AUTOINCREMENT,
    id_projeto    INTEGER NOT NULL,
    id_aluno      INTEGER NOT NULL,
    papel         TEXT    NOT NULL DEFAULT 'MEMBRO'
                  CHECK (papel IN ('LIDER', 'MEMBRO')),
    adicionado_em TEXT    NOT NULL DEFAULT (datetime('now', 'localtime')),
    FOREIGN KEY (id_projeto) REFERENCES projetos(id_projeto)
                ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (id_aluno)   REFERENCES usuarios(id_usuario)
                ON DELETE CASCADE ON UPDATE CASCADE,
    UNIQUE (id_projeto, id_aluno)
);

CREATE TABLE IF NOT EXISTS arquivos_projeto (
    id_arquivo    INTEGER PRIMARY KEY AUTOINCREMENT,
    id_projeto    INTEGER NOT NULL,
    nome_arquivo  TEXT    NOT NULL,
    caminho       TEXT    NOT NULL,
    tipo          TEXT    NOT NULL
                  CHECK (tipo IN ('PDF', 'ZIP', 'LINK', 'IMAGEM', 'OUTRO')),
    tamanho_kb    REAL,
    enviado_em    TEXT    NOT NULL DEFAULT (datetime('now', 'localtime')),
    FOREIGN KEY (id_projeto) REFERENCES projetos(id_projeto)
                ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS avaliacoes (
    id_avaliacao        INTEGER PRIMARY KEY AUTOINCREMENT,
    id_projeto          INTEGER NOT NULL,
    id_professor        INTEGER NOT NULL,
    nota_apresentacao   REAL    NOT NULL CHECK (nota_apresentacao BETWEEN 0 AND 10),
    nota_documentacao   REAL    NOT NULL CHECK (nota_documentacao BETWEEN 0 AND 10),
    nota_inovacao       REAL    NOT NULL CHECK (nota_inovacao     BETWEEN 0 AND 10),
    nota_tecnica        REAL    NOT NULL CHECK (nota_tecnica       BETWEEN 0 AND 10),
    nota_final          REAL    GENERATED ALWAYS AS (
                            ROUND(
                                (nota_apresentacao * 0.25 +
                                 nota_documentacao * 0.25 +
                                 nota_inovacao     * 0.20 +
                                 nota_tecnica      * 0.30), 2
                            )
                        ) STORED,
    feedback            TEXT,
    avaliado_em         TEXT    NOT NULL DEFAULT (datetime('now', 'localtime')),
    FOREIGN KEY (id_projeto)   REFERENCES projetos(id_projeto)
                ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (id_professor) REFERENCES usuarios(id_usuario)
                ON DELETE RESTRICT ON UPDATE CASCADE,
    UNIQUE (id_projeto, id_professor)
);

CREATE TABLE IF NOT EXISTS portfolio_visitas (
    id_visita      INTEGER PRIMARY KEY AUTOINCREMENT,
    id_projeto     INTEGER NOT NULL,
    empresa_nome   TEXT    NOT NULL,
    empresa_email  TEXT,
    interesse      TEXT    DEFAULT 'VISUALIZACAO'
                   CHECK (interesse IN ('VISUALIZACAO', 'CONTATO', 'RECRUTAMENTO')),
    visitado_em    TEXT    NOT NULL DEFAULT (datetime('now', 'localtime')),
    FOREIGN KEY (id_projeto) REFERENCES projetos(id_projeto)
                ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS relatorios (
    id_relatorio    INTEGER PRIMARY KEY AUTOINCREMENT,
    id_coordenador  INTEGER NOT NULL,
    tipo            TEXT    NOT NULL
                    CHECK (tipo IN ('PROJETOS_POR_TURMA', 'AVALIACOES_GERAL',
                                    'DESEMPENHO_ALUNOS', 'VISITAS_EMPRESAS')),
    filtro_aplicado TEXT,
    gerado_em       TEXT    NOT NULL DEFAULT (datetime('now', 'localtime')),
    FOREIGN KEY (id_coordenador) REFERENCES usuarios(id_usuario)
                ON DELETE RESTRICT ON UPDATE CASCADE
);

-- =============================================================================
--  ÍNDICES EVITA LER LINHA A LINHA
-- =============================================================================

CREATE INDEX IF NOT EXISTS idx_usuarios_email   ON usuarios(email);
CREATE INDEX IF NOT EXISTS idx_usuarios_perfil  ON usuarios(perfil);
CREATE INDEX IF NOT EXISTS idx_usuarios_turma   ON usuarios(id_turma);
CREATE INDEX IF NOT EXISTS idx_projetos_turma   ON projetos(id_turma);
CREATE INDEX IF NOT EXISTS idx_projetos_status  ON projetos(status);
CREATE INDEX IF NOT EXISTS idx_membros_projeto  ON membros_projeto(id_projeto);
CREATE INDEX IF NOT EXISTS idx_membros_aluno    ON membros_projeto(id_aluno);
CREATE INDEX IF NOT EXISTS idx_avaliacoes_proj  ON avaliacoes(id_projeto);
CREATE INDEX IF NOT EXISTS idx_avaliacoes_prof  ON avaliacoes(id_professor);

-- =============================================================================
--  TRIGGERS
-- =============================================================================

CREATE TRIGGER IF NOT EXISTS trg_projetos_update
    AFTER UPDATE ON projetos
    FOR EACH ROW
BEGIN
    UPDATE projetos
    SET    atualizado_em = datetime('now', 'localtime')
    WHERE  id_projeto = OLD.id_projeto;
END;

CREATE TRIGGER IF NOT EXISTS trg_incrementar_versao
    AFTER INSERT ON arquivos_projeto
    FOR EACH ROW
BEGIN
    UPDATE projetos
    SET    versao = versao + 1,
           atualizado_em = datetime('now', 'localtime')
    WHERE  id_projeto = NEW.id_projeto;
END;

CREATE TRIGGER IF NOT EXISTS trg_status_avaliacao
    AFTER INSERT ON avaliacoes
    FOR EACH ROW
BEGIN
    UPDATE projetos
    SET    status = 'AVALIADO',
           atualizado_em = datetime('now', 'localtime')
    WHERE  id_projeto = NEW.id_projeto;
END;

-- =============================================================================
--  VIEWS
-- =============================================================================

CREATE VIEW IF NOT EXISTS v_painel_aluno AS
SELECT
    u.id_usuario,
    u.nome              AS aluno,
    p.id_projeto,
    p.titulo,
    p.status,
    p.versao,
    t.nome_turma,
    a.nota_final,
    a.feedback,
    p.atualizado_em
FROM usuarios        u
JOIN membros_projeto mp ON mp.id_aluno    = u.id_usuario
JOIN projetos        p  ON p.id_projeto   = mp.id_projeto
JOIN turmas          t  ON t.id_turma     = p.id_turma
LEFT JOIN avaliacoes a  ON a.id_projeto   = p.id_projeto
WHERE u.perfil = 'ALUNO';

CREATE VIEW IF NOT EXISTS v_painel_professor AS
SELECT
    p.id_projeto,
    p.titulo,
    p.status,
    t.nome_turma,
    t.turno,
    GROUP_CONCAT(u.nome, ', ') AS alunos,
    a.nota_final,
    prof.nome                  AS professor_avaliador,
    p.atualizado_em
FROM projetos        p
JOIN turmas          t   ON t.id_turma    = p.id_turma
JOIN membros_projeto mp  ON mp.id_projeto = p.id_projeto
JOIN usuarios        u   ON u.id_usuario  = mp.id_aluno
LEFT JOIN avaliacoes a   ON a.id_projeto  = p.id_projeto
LEFT JOIN usuarios   prof ON prof.id_usuario = a.id_professor
GROUP BY p.id_projeto;

CREATE VIEW IF NOT EXISTS v_portfolio_publico AS
SELECT
    p.id_projeto,
    p.titulo,
    p.descricao,
    t.nome_turma,
    t.ano,
    a.nota_final,
    GROUP_CONCAT(u.nome, ', ') AS autores,
    COUNT(pv.id_visita)        AS total_visitas
FROM projetos         p
JOIN turmas           t  ON t.id_turma    = p.id_turma
JOIN membros_projeto  mp ON mp.id_projeto = p.id_projeto
JOIN usuarios         u  ON u.id_usuario  = mp.id_aluno
LEFT JOIN avaliacoes  a  ON a.id_projeto  = p.id_projeto
LEFT JOIN portfolio_visitas pv ON pv.id_projeto = p.id_projeto
WHERE p.status IN ('APROVADO', 'AVALIADO')
GROUP BY p.id_projeto
ORDER BY a.nota_final DESC;

-- =============================================================================
--  DADOS INICIAIS PARA TESTE
-- =============================================================================

INSERT OR IGNORE INTO turmas (nome_turma, turno, ano)
VALUES
    ('ADS-2025-MANHA',  'MATUTINO',   2025),
    ('ADS-2025-TARDE',  'VESPERTINO', 2025),
    ('ADS-2025-NOITE',  'NOTURNO',    2025);

INSERT OR IGNORE INTO usuarios (nome, email, senha, perfil)
VALUES ('Coordenador SENAC', 'admin@senac.br', 'admin123', 'COORDENADOR');