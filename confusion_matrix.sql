CREATE or replace FUNCTION stat_conf_matrix(
in_table_name text,
actual_class_column text,
predicted_class_column text,
out_table_name text) RETURNS void AS $$
DECLARE
    loop_var RECORD;
    sqlText text; 
    mapQuery text; 
    createTableQuery text;
    confusionMatrixDimension int;
    mappedArray text[];
    confusionMatrix integer[][];
    rowIterator integer[];  
BEGIN

   RAISE NOTICE 'Started generating the matrix';

   RAISE NOTICE 'Getting the number of classes';
   execute 'select count(distinct '||quote_ident($2)||') from '||quote_ident($1) into confusionMatrixDimension; 

   RAISE NOTICE 'Initializing the mapping array';
   confusionMatrix := array_fill(0,array[confusionMatrixDimension]);
   mapQuery = 'SELECT distinct on ('||quote_ident($2)||') '||quote_ident($2)||' as class_, dense_rank() over (order by '||quote_ident($2)||') as idx 
   FROM '||quote_ident($1);  

   RAISE NOTICE 'Creating the confusion matrix';
   createTableQuery = 'DROP TABLE if exists '||quote_ident($4)||'; CREATE TABLE if not exists '||quote_ident($4)||' (';
   
   FOR loop_var IN execute mapQuery LOOP 	
	mappedArray[loop_var.idx] = loop_var.class_;
	createTableQuery = createTableQuery||'class_'||loop_var.class_||' integer,';
   END LOOP;

   createTableQuery = overlay(createTableQuery placing ')' from (char_length(createTableQuery)) for 1);

   -- RAISE NOTICE '%', createTableQuery; 

   execute createTableQuery; 
   
   RAISE NOTICE 'Number of classes is %', confusionMatrixDimension ; 
   
    confusionMatrix := array_fill(0,array[confusionMatrixDimension,confusionMatrixDimension]);
	
    sqlText = 'select p2.idx as actual_class, p3.idx as inferred_class, count(*) from 
		'||quote_ident($1)||' as p1,
		(select distinct on ('||quote_ident($2)||') '||quote_ident($2)||', dense_rank() over (order by '||quote_ident($2)||') as idx from '||quote_ident($1)||') as p2,
		(select distinct on ('||quote_ident($2)||') '||quote_ident($2)||', dense_rank() over (order by '||quote_ident($2)||') as idx from '||quote_ident($1)||') as p3 
			where p1.'||quote_ident($2)||'= p2.'||quote_ident($2)||'
			and p1.'||quote_ident($3)||' = p3.'||quote_ident($2)||'
			group by p2.idx, p3.idx
			order by p2.idx, p3.idx';
     FOR loop_var IN execute sqlText LOOP  
       confusionMatrix[loop_var.inferred_class][loop_var.actual_class] = loop_var.count;  -- already mapped via query
    END LOOP;  
	FOREACH rowIterator SLICE 1 in ARRAY confusionMatrix 
		LOOP  
			RAISE NOTICE 'inserting values %', rowIterator;
			execute 'insert into '||quote_ident($4)||' values ('||array_to_string(rowIterator,',')||')'; 
		END LOOP; 
		
    RAISE NOTICE 'Done.'; 
END;
$$ LANGUAGE plpgsql;

Create table prediction_table 
(id serial, class_name_or_id text , actual_class text , predicted_class text);

insert into prediction_table (class_name_or_id, actual_class, predicted_class)
values ('foo', 'c1', 'c2'),
('foo2', 'c1', 'c1'),
('foo3', 'c2', 'c2'),
('foo4', 'c2', 'c2'),
('foo5', 'c2', 'c3'),
('foo6', 'c3', 'c1'),
('foo7', 'c1', 'c1');

select * from stat_conf_matrix(
'prediction_table',
'actual_class',
'predicted_class',
'confusion_table');