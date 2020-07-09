use Teest 
GO
drop table t1
drop table t2
drop table t3

CREATE TABLE t1 ( id int identity )
CREATE TABLE t2 ( id int identity, t1 int, val int )
CREATE TABLE t3 ( id int identity, t2 int, val int )

SELECT id as [t1.id] FROM t1
SELECT id as [t2.id], t1 as [t2.t1], val as [t2.val] FROM t2
SELECT id as [t3.id], t2 as [t3.t2], val as [t3.val] FROM t3
