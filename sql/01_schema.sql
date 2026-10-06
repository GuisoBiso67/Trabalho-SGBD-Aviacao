CREATE TABLE INVESTIGACAO
(
investigacao_codigo SMALLINT PRIMARY KEY,
investigacao_aeronave_liberada BOOLEAN NOT NULL,
investigacao_status TEXT NOT NULL
);

CREATE TABLE OCORRENCIA
(
codigo_ocorrencia INTEGER PRIMARY KEY,
ocorrencia_classificacao TEXT NOT NULL,
ocorrencia_latitude DOUBLE PRECISION,
ocorrencia_longitude DOUBLE PRECISION,
ocorrencia_cidade TEXT,
ocorrencia_uf CHAR(2),
ocorrencia_aerodromo CHAR(4),
ocorrencia_dia DATE,
ocorrencia_hora TIME,
divulgacao_relatorio_numero TEXT,
divulgacao_relatorio_publicado BOOLEAN,
divulgacao_dia_publicacao DATE,
investigacao_codigo SMALLINT NOT NULL,
total_recomendacoes INTEGER,
total_aeronaves_envolvidas INTEGER,
ocorrencia_saida_pista BOOLEAN,
FOREIGN KEY (investigacao_codigo) REFERENCES INVESTIGACAO(investigacao_codigo)
);

CREATE TABLE AERONAVE_QTD_MOTOR
(
aeronave_motor_quantidade SMALLINT PRIMARY KEY,
aeronave_motor_descricao TEXT NOT NULL
);

CREATE TABLE AERONAVE
(
aeronave_matricula VARCHAR(10) PRIMARY KEY,
aeronave_tipo_equipamento TEXT,
aeronave_fabricante TEXT,
aeronave_modelo TEXT,
aeronave_tipo_icao CHAR(10),
aeronave_motor_tipo TEXT,
aeronave_pmd INTEGER,
aeronave_assentos SMALLINT,
aeronave_ano_fabricacao SMALLINT,
aeronave_pais_registro TEXT,
aeronave_motor_quantidade SMALLINT NOT NULL,
FOREIGN KEY (aeronave_motor_quantidade) REFERENCES AERONAVE_QTD_MOTOR(aeronave_motor_quantidade)
);

CREATE TABLE AERONAVE_OCORRENCIA
(
aeronave_voo_origem TEXT,
aeronave_voo_destino TEXT,
aeronave_fase_operacao TEXT,
aeronave_tipo_operacao TEXT,
aeronave_nivel_dano TEXT,
aeronave_fatalidades_total SMALLINT,
codigo_ocorrencia INTEGER NOT NULL,
aeronave_matricula VARCHAR(10) NOT NULL,
PRIMARY KEY (codigo_ocorrencia, aeronave_matricula),
FOREIGN KEY (codigo_ocorrencia) REFERENCES OCORRENCIA(codigo_ocorrencia),
FOREIGN KEY (aeronave_matricula) REFERENCES AERONAVE(aeronave_matricula)
);

CREATE TABLE TIPO_OCORRENCIA
(
id_ocorrencia VARCHAR(10) PRIMARY KEY,
descricao TEXT NOT NULL
);

CREATE TABLE OCORRENCIA_TIPO
(
codigo_ocorrencia INTEGER NOT NULL,
taxonomia_tipo_icao VARCHAR(10) NOT NULL,
PRIMARY KEY (codigo_ocorrencia, taxonomia_tipo_icao),
FOREIGN KEY (codigo_ocorrencia) REFERENCES OCORRENCIA(codigo_ocorrencia),
FOREIGN KEY (taxonomia_tipo_icao) REFERENCES TIPO_OCORRENCIA(id_ocorrencia)
);

CREATE TABLE FATOR
(
codigo_fator SMALLINT PRIMARY KEY,
fator_nome TEXT,
fator_aspecto TEXT,
fator_condicionante TEXT,
fator_area TEXT
);

CREATE TABLE FATOR_OCORRENCIA
(
codigo_fator INTEGER NOT NULL,
codigo_ocorrencia INTEGER NOT NULL,
PRIMARY KEY (codigo_fator, codigo_ocorrencia),
FOREIGN KEY (codigo_fator) REFERENCES FATOR(codigo_fator),
FOREIGN KEY (codigo_ocorrencia) REFERENCES OCORRENCIA(codigo_ocorrencia)
);

CREATE TABLE RECOMENDACAO_TIPO
(
recomendacao_numero TEXT PRIMARY KEY,
recomendacao_conteudo TEXT NOT NULL
);

CREATE TABLE DESTINATARIO
(
recomendacao_destinatario_sigla VARCHAR(20) PRIMARY KEY,
recomendacao_destinatario_nome TEXT NOT NULL
);

CREATE TABLE RECOMENDACAO
(
recomendacao_dia_assinatura DATE,
recomendacao_status TEXT,
recomendacao_dia_encaminhamento DATE,
recomendacao_dia_feedback DATE,
recomendacao_numero TEXT NOT NULL,
destinatario_sigla VARCHAR(20) NOT NULL,
codigo_ocorrencia INTEGER NOT NULL,
PRIMARY KEY (numero_recomendacao, codigo_ocorrencia, recomendacao_numero),
FOREIGN KEY (recomendacao_numero) REFERENCES RECOMENDACAO_TIPO(recomendacao_numero),
FOREIGN KEY (destinatario_sigla) REFERENCES DESTINATARIO(recomendacao_destinatario_sigla),
FOREIGN KEY (codigo_ocorrencia) REFERENCES OCORRENCIA(codigo_ocorrencia)
);
