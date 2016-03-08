# Confusion Matrix
plpgsql function for generating a confusion matrix represented as a table

##### Function Description
stat_conf_matrix(
in_table_name text,
actual_class_column text,
predicted_class_column text,
out_table_name text)

**in_table_name** -> Name of the table where the predictions are stored 

**actual_class_column** -> Name of the column that stores the ground truth / correct class of a classified entity

**predicted_class_column** -> Name of the column that stores the inferred / predicted class of a classified entity

**out_table_name** -> Name of the table that will store the confusion matrix. **Warning** The table will be overwritten if it already exists.

##### Example

```sql
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
```
