
--      a) Space consumption of ‘table_to_delete’ table before and after each operation;
--		 table size before delete 602456064 bytes 
--       table size after delete 602603520 bytes
--       table size after vacum  401629184 bytes


--       2 table size  602439680 bytes
--       2 table size after truncate  8192 bytes
--
--      b) Duration of each operation (DELETE, TRUNCATE)
--		delete 31 sec vacum 20 sec
--      truncate 1 sec
-- 