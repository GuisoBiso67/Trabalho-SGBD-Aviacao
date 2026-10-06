-- ============================================================
-- 4.2 GATILHO E PROCEDIMENTO ARMAZENADO
-- ============================================================

-- 4.2.1 TRIGGER (GATILHO)
-- O trigger impede que sejam colocadas fatalidades negativas ao inserir uma tupla na tabela aeronave_ocorrencia.

CREATE OR REPLACE FUNCTION validar_fatalidades()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.aeronave_fatalidades_total < 0 THEN
        RAISE EXCEPTION 'O número de fatalidades não pode ser negativo.';
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_validar_fatalidades
BEFORE INSERT OR UPDATE ON aeronave_ocorrencia
FOR EACH ROW
EXECUTE FUNCTION validar_fatalidades();


-- 4.2.2 PROCEDIMENTO ARMAZENADO E FUNÇÃO AUXILIAR
-- O procedimento armazenado gera um relatório resumido de um modelo de aeronave, reunindo informações relevantes, como fabricante, total de ocorrências, tipo de ocorrência mais frequente, fase da operação mais recorrente e principal fator contribuinte.

-- Função auxiliar
CREATE OR REPLACE FUNCTION relatorio_modelo_aviao
(IN mod_aeronave aeronave.aeronave_modelo%type)
RETURNS TABLE (
    fabricante TEXT,
    modelo TEXT,
    total_ocorrencias INTEGER,
    tipo_mais_frequente TEXT,
    fase_mais_frequente TEXT,
    fator_mais_frequente TEXT
) AS $$
DECLARE 
    v_fabricante TEXT;
    v_total_ocorrencias INTEGER;
    v_tipo_mais_frequente TEXT;
    v_fase_mais_frequente TEXT;
    v_fator_mais_frequente TEXT;
BEGIN
    SELECT a.aeronave_fabricante INTO v_fabricante
    FROM aeronave a
    WHERE a.aeronave_modelo = mod_aeronave
    LIMIT 1;

    SELECT COUNT(*) INTO v_total_ocorrencias
    FROM aeronave_ocorrencia ao, aeronave a
    WHERE ao.aeronave_matricula = a.aeronave_matricula AND
          a.aeronave_modelo = mod_aeronave;

    IF v_total_ocorrencias = 0 THEN
        RAISE WARNING 'MODELO % não encontrado !!', mod_aeronave;
        RETURN;
    END IF;

    SELECT tio.descricao INTO v_tipo_mais_frequente
    FROM aeronave_ocorrencia ao, aeronave a, ocorrencia_tipo ot, tipo_ocorrencia tio
    WHERE ao.aeronave_matricula = a.aeronave_matricula AND
          a.aeronave_modelo = mod_aeronave AND
          ao.codigo_ocorrencia = ot.codigo_ocorrencia AND
          ot.taxonomia_tipo_icao = tio.id_ocorrencia
    GROUP BY tio.descricao
    ORDER BY COUNT(*) DESC
    LIMIT 1;

    SELECT ao.aeronave_fase_operacao INTO v_fase_mais_frequente
    FROM aeronave_ocorrencia ao, aeronave a
    WHERE ao.aeronave_matricula = a.aeronave_matricula AND
          a.aeronave_modelo = mod_aeronave
    GROUP BY ao.aeronave_fase_operacao
    ORDER BY COUNT(*) DESC
    LIMIT 1;

    SELECT f.fator_nome INTO v_fator_mais_frequente
    FROM aeronave_ocorrencia ao, aeronave a, fator_ocorrencia fo, fator f
    WHERE ao.aeronave_matricula = a.aeronave_matricula AND
          a.aeronave_modelo = mod_aeronave AND
          ao.codigo_ocorrencia = fo.codigo_ocorrencia AND
          fo.codigo_fator = f.codigo_fator
    GROUP BY f.fator_nome
    ORDER BY COUNT(*) DESC
    LIMIT 1;

    fabricante := v_fabricante;
    modelo := mod_aeronave;
    total_ocorrencias := v_total_ocorrencias;
    tipo_mais_frequente := v_tipo_mais_frequente;
    fase_mais_frequente := v_fase_mais_frequente;
    fator_mais_frequente := v_fator_mais_frequente;

    RETURN NEXT;
    RETURN;
END $$ LANGUAGE 'plpgsql';

-- Procedimento Armazenado
CREATE OR REPLACE PROCEDURE relatorio_modelo_aviao_proc(
    IN mod_aeronave aeronave.aeronave_modelo%TYPE
)
AS $$
DECLARE
    v_row RECORD;
BEGIN
    FOR v_row IN SELECT * FROM relatorio_modelo_aviao(mod_aeronave)
    LOOP
        RAISE NOTICE 'Fabricante: % | Modelo: % | Total Ocorrencias: % | Tipo mais frequente: % | Fase mais frequente: % | Fator mais frequente: %',
        v_row.fabricante,
        v_row.modelo,
        v_row.total_ocorrencias,
        v_row.tipo_mais_frequente,
        v_row.fase_mais_frequente,
        v_row.fator_mais_frequente;
    END LOOP;
END $$ LANGUAGE plpgsql;
