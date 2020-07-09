CREATE PROCEDURE dbo.GetDifferencesByT2Val
  @xml_in XML
, @t2_val_in INT
, @cnt_out INT OUTPUT
AS
/*
 * Получаем количество различий между XML и данными в таблицах по значению t2_val
 */
BEGIN
	--PRINT('GetDifferencesByT2Val: Получаем количество различий между XML и данными в таблицах с учетом полученного из XML значения('+CAST(@t2_val_in as CHAR(3))+')')
	SELECT @cnt_out = COUNT(*)
	FROM (
		SELECT
			  xmlt2.v.value('val[1]', 'int') as t2_val
			, CASE xmlt3.v.value('.', 'int')
			  WHEN 0 THEN NULL
			  ELSE xmlt3.v.value('.', 'int') 
			END as t3_val
		FROM @xml_in.nodes('/t1/t2') AS xmlt2(v)
		LEFT JOIN @xml_in.nodes('/t1/t2/t3') AS xmlt3(v) ON xmlt3.v.value('../val[1]', 'int') = xmlt2.v.value('val[1]', 'int')
		EXCEPT
		SELECT
			  t2.val
			, CASE t3.val
				WHEN 0 THEN NULL
				ELSE t3.val 
			END
		FROM t2
		LEFT JOIN t3 ON t3.t2 = t2.id
	) t
	WHERE t2_val = @t2_val_in
	--PRINT('GetDifferencesByT2Val: ' + CAST(@cnt_out AS CHAR(3)) + ' различий обнаружено')
END;

CREATE PROCEDURE dbo.GetFirstDifferentT2ValFromXml
@xml_in XML
, @t2_first_out INT OUTPUT
AS
/*
 * Получаем первое отличающееся значение из XML(/t2/val) 
 */
BEGIN
	--PRINT('GetFirstDifferentT2ValFromXml: Получаем первое отличающееся от t2.val значение из XML')
	SELECT TOP 1 @t2_first_out = t.t2_val
	FROM (
		SELECT
			  xmlt2.v.value('val[1]', 'int') as t2_val
			, xmlt3.v.value('.', 'int') as t3_val
		FROM @xml_in.nodes('/t1/t2') AS xmlt2(v)
		LEFT JOIN @xml_in.nodes('/t1/t2/t3') AS xmlt3(v) ON xmlt3.v.value('../val[1]', 'int') = xmlt2.v.value('val[1]', 'int')
		EXCEPT
		SELECT
			  t2.val
			, t3.val
		FROM t2
		LEFT JOIN t3 ON t3.t2 = t2.id
	) AS t
	--PRINT('GetFirstDifferentT2ValFromXml: Получено значение /t1/t2/val =' + CAST(@t2_first_out AS CHAR(3)))
END;

CREATE PROCEDURE dbo.GetFirstDifferentT3ValFromXml
@xml_in XML
, @t2_val_in INT
, @t3_first_out INT OUTPUT 
AS
/*
 * Получаем первое отличающееся значение из XML(/t1/t2/t3) с использованием t2.val 
 */
BEGIN
	--PRINT('GetFirstDifferentT3ValFromXml: Получаем первое отличающееся от t3.val значение из XML /t1/t2/t3 с учетом t2.val = ' + CAST(@t2_val_in AS CHAR(3)))
	SELECT TOP 1 @t3_first_out = t3_val
	FROM (
		SELECT
			  xmlt2.v.value('val[1]', 'int') as t2_val
			, xmlt3.v.value('.', 'int') as t3_val
		FROM @xml_in.nodes('/t1/t2') AS xmlt2(v)
		LEFT JOIN @xml_in.nodes('/t1/t2/t3') AS xmlt3(v) ON xmlt3.v.value('../val[1]', 'int') = xmlt2.v.value('val[1]', 'int')
		EXCEPT
		SELECT
			  t2.val
			, t3.val
		FROM t2
		LEFT JOIN t3 ON t3.t2 = t2.id
	) t
	WHERE t2_val = @t2_val_in
	--PRINT('GetFirstDifferentT3ValFromXml: Получено значение из /t1/t2/t3 = ' + CAST(@t3_first_out AS CHAR(3)))
END;

CREATE PROCEDURE dbo.GetT1Id
@t1_id_out INT OUTPUT
AS
/*
 * Получаем t1.id. 
 * Если t1.id не найдено - создаем новый t1.id
 */
BEGIN TRANSACTION
	DECLARE
		@buf INT
	--PRINT('GetT1Id: Получаем значение t1.id')
	SELECT TOP 1 @buf = t1.id
	FROM t1
	IF @buf IS NULL
		BEGIN
			--PRINT('GetT1Id: Значение не обнаружено. Создаем новую запись в t1')
			SET NOCOUNT ON
			INSERT INTO t1 DEFAULT VALUES
			SET @buf = SCOPE_IDENTITY()
			SET NOCOUNT OFF
			--PRINT('GetT1Id: Запись создана')
		END
	SET @t1_id_out = @buf
	--PRINT('GetT1Id: Получено из t1 значение t1.id = ' + CAST(@t1_id_out AS CHAR(3)))
COMMIT;

CREATE PROCEDURE dbo.GetT2IdByT2Val
  @t2_val_in INT
, @t2_id_out INT OUTPUT
, @t1_id_out INT OUTPUT
AS 
/*
 * Получаем t2.id по значению t2.val, затем t2.t1 как t1.id.
 * Если t2.id не найдено - создаем новый t2.id 
 */
BEGIN TRANSACTION
	DECLARE
		@buf INT
	--PRINT('GetT2IdByT2Val: Получаем t2.id по значению t2.val (' + CAST(@t2_val_in as CHAR(3)) + ')')
	SELECT TOP 1 @buf = t2.id
	FROM t2
	WHERE t2.val = @t2_val_in
	IF @buf IS NULL
		BEGIN
			--PRINT('GetT2IdByT2Val: В таблице не обнаружена запись со значением t2.val = '+CAST(@t2_val_in as CHAR(3)))
			--PRINT('GetT2IdByT2Val: Создаем новую запись в таюлице t2.')
			--PRINT('GetT2IdByT2Val: Получаем t1.id для записи в t2.t1')
			EXECUTE GetT1Id @t1_id_out = @t1_id_out OUTPUT
			--PRINT('GetT2IdByT2Val: Получено значение из t1.id = ' + CAST(@t1_id_out AS CHAR(3)))
			--PRINT('GetT2IdByT2Val: Добавляем новую запись в t2 со следующими значениями:')
			--PRINT('GetT2IdByT2Val: t2.t1 = ' + CAST(@t1_id_out AS CHAR(3)))
			--PRINT('GetT2IdByT2Val: t2.val = ' + CAST(@t2_val_in AS CHAR(3)))
			SET NOCOUNT ON
			INSERT INTO t2(t1, val) VALUES(@t1_id_out, @t2_val_in)
			SET @buf = SCOPE_IDENTITY()
			SET NOCOUNT OFF
			--PRINT('GetT12dByT2Val: Новая запись создана')
		END
	ELSE
		BEGIN
			--PRINT('GetT2IdByT2Val: Обнаружена запись t2.id = ' + CAST(@t2_id_out AS CHAR(3)))
			--PRINT('GetT2IdByT2Val: Получаем значение t2.t1 по t2.id = ' + CAST(@t2_id_out as CHAR(3)))
			SELECT TOP 1 @t1_id_out = t2.t1
			FROM t2
			WHERE t2.id = @buf
		END
	SET @t2_id_out = @buf
	--PRINT('GetT2IdByT2Val: Получены значения:')
	--PRINT('GetT2IdByT2Val: t2.id = ' + CAST(@t2_id_out AS CHAR(3)))
	--PRINT('GetT2IdByT2Val: t2.t1 = ' + CAST(@t1_id_out AS CHAR(3)))
COMMIT;

CREATE PROCEDURE dbo.GetT3IdByT3ValAndT2Id
@xml_in XML
, @t3_val_in INT
, @t2_id_in INT
, @t3_id_out INT OUTPUT
AS
/*
 * Получаем t3.id по значениям t3.val и t3.t2.
 * Если t3.id не найдено - создаем новый t3.id 
 */
BEGIN TRANSACTION
	DECLARE
		@buf INT
	--PRINT('GetT3IdByT3ValAndT2Id: Получаем t3.id по полученному из XML значению (' + CAST(@t3_val_in AS CHAR(3)) + ') используя t2.id = ' + CAST(@t2_id_in AS CHAR(3)))
	SELECT TOP 1 @buf = t3.id FROM t3 WHERE t3.val = @t3_val_in AND t3.t2 = @t2_id_in
	IF @buf IS NULL 
		BEGIN 
			--PRINT('GetT3IdByT3ValAndT2Id: Запись со значением t3.val не обнаружена. Создаем новую запись со значениями t3.t2 = ' + CAST(@t2_id_in AS CHAR(3)) + ' и t3.val = ' + CAST(@t3_val_in AS CHAR(3))) 
			SET NOCOUNT ON
			INSERT INTO t3(t2, val) VALUES (@t2_id_in, @t3_val_in)
			SET @buf = SCOPE_IDENTITY()
			SET NOCOUNT OFF
			--PRINT('GetT3IdByT3ValAndT2Id: Запись создана')
		END
	SET @t3_id_out = @buf
	--PRINT('GetT3IdByT3ValAndT2Id: Получено t3.id = ' + CAST(@t3_id_out AS CHAR(3)))
COMMIT;

CREATE PROCEDURE dbo.GetTotalDifferences
@xml_in XML
, @cnt_out INT OUTPUT
AS 
/*
 * Получаем общее количество различий между данными в XML и данными в таблицах 
 */
BEGIN
	--PRINT('GetTotalDifferences: Получаем общее количество различий между XML и таблицами')
	SELECT @cnt_out = COUNT(*)
	FROM (
		SELECT
			  xmlt2.v.value('val[1]', 'int') as t2_val
			, CASE xmlt3.v.value('.', 'int')
				WHEN 0 THEN NULL
				ELSE xmlt3.v.value('.', 'int')
			  END
				AS t3_val
		FROM @xml_in.nodes('/t1/t2') AS xmlt2(v)
		LEFT JOIN @xml_in.nodes('/t1/t2/t3') AS xmlt3(v) ON xmlt3.v.value('../val[1]', 'int') = xmlt2.v.value('val[1]', 'int')
		EXCEPT
		SELECT
			  t2.val
			, CASE t3.val
				WHEN 0 THEN NULL
				ELSE t3.val 
			  END
		FROM t2
		LEFT JOIN t3 ON t3.t2 = t2.id
	) AS t
	--PRINT('GetTotalDifferences: '+CAST(@cnt_out AS CHAR(3))+' различий обнаружено')
END;

CREATE PROCEDURE dbo.ParseXml
  @xml_in XML
, @t1_id_out INT OUTPUT
AS
/*
 * Парсим XML к виду t2_val и t3_val.
 * Проверяем различия между XML и таблицами
 * При необходимости вносим изменения
 * Возвращаем t1.id или t2.t1
 */
BEGIN
	DECLARE
		@totalDifferences INT
	--PRINT('ParseXml: Получаем количество различий между XML и таблицами t2, t3')
	EXECUTE GetTotalDifferences @xml_in = @xml_in, @cnt_out = @totalDifferences OUTPUT
	WHILE(@totalDifferences != 0)
		BEGIN
			DECLARE
				  @t2_first INT
				, @t2_id INT
				, @differencesInT2 INT
			--PRINT('ParseXml: ' + CAST(@totalDifferences AS NVARCHAR(MAX)) + ' различий обнаружено')
			--PRINT('ParseXml: Получаем первое отличающееся от t2.val значение из XML')
			EXECUTE GetFirstDifferentT2ValFromXml
				  @xml_in = @xml_in
				, @t2_first_out = @t2_first OUTPUT
			--PRINT('ParseXml: Получено значение /t1/t2/val = '+ CAST(@t2_first AS NVARCHAR(MAX)))
			--PRINT('ParseXml: Получаем количество отличий между XML и таблицами с учетом полученного из XML значения /t1/t2/val (' + CAST(@t2_first as CHAR(3)) + ')')
			EXECUTE GetDifferencesByT2Val
				  @xml_in = @xml_in
				, @t2_val_in = @t2_first
				, @cnt_out = @differencesInT2 OUTPUT  
			WHILE (@differencesInT2 != 0)
				BEGIN
					DECLARE
						@t3_first INT
						, @differencesInT3 INT
					--PRINT('ParseXml: '+ CAST(@differencesInT2 as CHAR(3)) + ' различий обнаружено')
					--PRINT('ParseXml: Получаем t2.id по полученному из XML /t1/t2/val первому отличающемуся значению ('+CAST(@t2_first as CHAR(3))+')')
					EXECUTE GetT2IdByT2Val
						  @t2_val_in = @t2_first
						, @t2_id_out = @t2_id OUTPUT
						, @t1_id_out = @t1_id_out OUTPUT
					--PRINT('ParseXml: Получены значения из t2:')
					--PRINT('ParseXml: t2.id = ' + CAST(@t2_id as CHAR(3)))
					--PRINT('ParseXml: t2.t1(t1.id) = ' + CAST(@t1_id_out as CHAR(3)))
					--PRINT('ParseXml: Получаем количество различий между XML и таблицами с учетом полученных значений:')
					--PRINT('ParseXml: t2.val = ' + CAST(@t2_first AS CHAR(3)))
					EXECUTE GetDifferencesByT2Val @xml_in = @xml_in, @t2_val_in = @t2_first, @cnt_out = @differencesInT3 OUTPUT
					
					WHILE (@differencesInT3 != 0)
						BEGIN
							DECLARE
								@t3_id INT
							--PRINT('ParseXml: ' + CAST(@differencesInT3 AS CHAR(3)) + ' различий обнаружено')
							--PRINT('ParseXml: Получаем первое отличающееся от t3.val значение из XML /t1/t2/t3 с учетом t2.val = ' + CAST(@t2_first AS CHAR(3)))
							EXECUTE GetFirstDifferentT3ValFromXml
								  @xml_in = @xml_in
								, @t2_val_in = @t2_first
								, @t3_first_out = @t3_first OUTPUT
							--PRINT('ParseXml: Получено значение из /t1/t2/t3 = ' + CAST(@t3_first AS CHAR(3)))	
							--PRINT('ParseXml: Получаем t3.id по полученному из XML значению (' + CAST(@t3_first AS CHAR(3)) + ') используя t2.id = ' + CAST(@t2_id AS CHAR(3)))
							EXECUTE GetT3IdByT3ValAndT2Id
								  @xml_in = @xml_in
								, @t3_val_in = @t3_first
								, @t2_id_in = @t2_id
								, @t3_id_out = @t3_id OUTPUT
							--PRINT('ParseXml: Получено t3.id = ' + CAST(@t3_id AS CHAR(3)))
							--PRINT('ParseXml: Получаем количество различий между XML и таблицами с учетом полученных значений:')
							--PRINT('ParseXml: t2.val = ' + CAST(@t2_first AS CHAR(3)))
							EXECUTE GetDifferencesByT2Val @xml_in = @xml_in, @t2_val_in = @t2_first, @cnt_out = @differencesInT3 OUTPUT
						END
						--PRINT('ParseXml: Получаем количество отличий между XML и таблицами с учетом полученного из XML значения /t1/t2/val (' + CAST(@t2_first as CHAR(3)) + ')')
						EXECUTE GetDifferencesByT2Val @xml_in = @xml_in, @t2_val_in = @t2_first, @cnt_out = @differencesInT2 OUTPUT
				END
			--PRINT('ParseXml: Получаем количество различий между XML и таблицами t2, t3')
			EXECUTE GetTotalDifferences @xml_in = @xml_in, @cnt_out = @totalDifferences OUTPUT
		END
		--PRINT('ParseXml: Получено значение t1.id = ' + CAST(@t1_id_out as CHAR(3)))
END;
