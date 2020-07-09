use Teest 
DECLARE @test1 xml = '<t1><t2><val>1</val><t3>10</t3><t3>20</t3></t2><t2><val>2</val><t3>10</t3></t2></t1>'
		, @test2 xml = '<t1><t2><val>2</val><t3>10</t3></t2><t2><val>1</val><t3>10</t3><t3>20</t3></t2></t1>'
		, @test3 xml = '<t1><t2><val>2</val></t2></t1>'
		, @test4 xml = '<t1><t2><val>2</val><t3>10</t3></t2></t1>'
		, @test5 xml = '<t1><t2><val>2</val><t3/></t2></t1>'
		, @t1_id int
EXEC ParseXml @xml_in = @test1, @t1_id_out = @t1_id OUTPUT
PRINT(CAST(@t1_id as NVARCHAR(MAX)))