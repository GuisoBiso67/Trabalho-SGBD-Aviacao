-- ============================================================
-- 4. ESPECIFICAÇÃO DE CONSULTAS EM SQL
-- ============================================================

-- 4.1.1 Quais são as 10 cidades que apresentam maior número de ocorrências?
SELECT ocorrencia_cidade, COUNT(*) AS total_ocorrencias
FROM ocorrencia
GROUP BY ocorrencia_cidade
ORDER BY total_ocorrencias DESC
LIMIT 10;


-- 4.1.2 Quais fatores contribuintes estão mais associados às ocorrências com fatalidades?
SELECT f.fator_nome, SUM(ao.aeronave_fatalidades_total) AS total_fatalidades
FROM fator f, fator_ocorrencia fo, aeronave_ocorrencia ao
WHERE f.codigo_fator = fo.codigo_fator AND
      fo.codigo_ocorrencia = ao.codigo_ocorrencia
GROUP BY f.fator_nome
HAVING SUM(ao.aeronave_fatalidades_total) > 0
ORDER BY total_fatalidades DESC;


-- 4.1.3 Quais os modelos (e seus fabricantes) de aeronaves estão mais envolvidos em ocorrências?
SELECT a.aeronave_modelo, a.aeronave_fabricante, COUNT(ao.codigo_ocorrencia) AS total_ocorrencias
FROM aeronave a, aeronave_ocorrencia ao
WHERE a.aeronave_matricula = ao.aeronave_matricula
GROUP BY a.aeronave_fabricante, a.aeronave_modelo
ORDER BY total_ocorrencias DESC;


-- 4.1.4 Entre as ocorrências envolvendo aeronaves do modelo ATR-72-212A, quais foram os tipos de ocorrência mais frequentes?
SELECT a.aeronave_modelo, t.descricao, COUNT(*) AS quantidade
FROM aeronave a, aeronave_ocorrencia ao, ocorrencia_tipo ot, tipo_ocorrencia t
WHERE a.aeronave_matricula = ao.aeronave_matricula AND
      ao.codigo_ocorrencia = ot.codigo_ocorrencia AND
      ot.taxonomia_tipo_icao = t.id_ocorrencia AND
      a.aeronave_modelo = 'ATR-72-212A'
GROUP BY a.aeronave_modelo, t.descricao
ORDER BY quantidade DESC;


-- 4.1.5 Quais fabricantes de aeronaves apresentam o maior número de ocorrências registradas?
SELECT a.aeronave_fabricante, COUNT(*) AS total_ocorrencias
FROM aeronave a JOIN aeronave_ocorrencia ao
ON a.aeronave_matricula = ao.aeronave_matricula
GROUP BY a.aeronave_fabricante
ORDER BY total_ocorrencias DESC;


-- 4.1.6 Quais fabricantes de aeronaves apresentam um total de fatalidades superior à média registrada entre todos os fabricantes?
SELECT aeronave_fabricante, total_fatalidades
FROM (
    SELECT a.aeronave_fabricante, SUM(ao.aeronave_fatalidades_total) AS total_fatalidades
    FROM aeronave_ocorrencia ao, aeronave a
    WHERE a.aeronave_matricula = ao.aeronave_matricula AND
          a.aeronave_fabricante IS NOT NULL
    GROUP BY a.aeronave_fabricante
) AS totais_por_fabricante
WHERE total_fatalidades > (
    SELECT AVG(total_fatalidades)
    FROM (
        SELECT SUM(ao.aeronave_fatalidades_total) AS total_fatalidades
        FROM aeronave_ocorrencia ao, aeronave a
        WHERE a.aeronave_matricula = ao.aeronave_matricula
        GROUP BY a.aeronave_fabricante
    ) AS media_base
)
ORDER BY total_fatalidades DESC;


-- 4.1.7 Quais aeronaves apresentam um número de ocorrências superior à média geral de ocorrências por aeronave?
SELECT a.aeronave_matricula, a.aeronave_modelo, COUNT(*) AS total_ocorrencias
FROM aeronave a JOIN aeronave_ocorrencia ao
ON a.aeronave_matricula = ao.aeronave_matricula
WHERE a.aeronave_modelo <> 'DESCONHECIDO'
GROUP BY a.aeronave_matricula, a.aeronave_modelo
HAVING COUNT(*) > (
    SELECT AVG(qtd)
    FROM (
        SELECT COUNT(*) AS qtd
        FROM aeronave_ocorrencia
        GROUP BY aeronave_matricula
    ) AS media
)
ORDER BY total_ocorrencias DESC;


-- 4.1.8 Para quais destinatários relacionadas à ocorrência com o maior número de fatalidades e quantas recomendações cada destinatário recebeu?
SELECT d.recomendacao_destinatario_nome, COUNT(*)
FROM recomendacao r, recomendacao_tipo rc, destinatario d
WHERE r.recomendacao_numero = rc.recomendacao_numero AND
      r.destinatario_sigla = d.recomendacao_destinatario_sigla AND
      r.codigo_ocorrencia = (
          SELECT o.codigo_ocorrencia
          FROM ocorrencia o, aeronave_ocorrencia ao
          WHERE o.codigo_ocorrencia = ao.codigo_ocorrencia AND
                ao.aeronave_fatalidades_total IS NOT NULL
          GROUP BY o.codigo_ocorrencia
          ORDER BY SUM(ao.aeronave_fatalidades_total) DESC
          LIMIT 1
      )
GROUP BY d.recomendacao_destinatario_nome
ORDER BY count DESC;
