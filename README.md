# SQLusine
## A SQL Query Factory for R

SQLusine is designed to be a flexible SQL query generator for R. It has the following design goals:

- Easily extensible to any flavor of SQL
- Readable and straightforward codebase
- Easy to program against
- Creates SQL that can be well optimized
- Low dependencies

To this end, SQLusine:

- Uses S3 methods throughout, dispatching to generate SQL based on the database connection object
- Separates query building from SQL rendering, so that a single query can be rendered in any supported database flavor at any time. 
- Uses standard evaluation and consistent design patterns to construct SQL from string arguments. 
- Uses data structures that can be easily traversed and analyzed to allow for optimizing during SQL rendering
- Writes SQL that can be easily optimized by a SQL engine

SQLusine is in early alpha and can only be installed from github. The API is subject to constant change and no guarantees are made in usability, accuracy, performance, or stability. 


## Prior Art

+ dplyr
  - Dplyr can use a database backend and generate SQL from dplyr code. Focused on performing data processing rather than generating SQL, and hides the SQL generation as much as possible. 
  - Doesn't appear to perform much optimization during SQL rendering, and as such can in some situations create inefficient SQL code. 
+ rquery
  - SQLusine draws inspiration from rquery's approach to SQL generation--keeping the query building and SQL rendering steps separate, and keeping query building agnostic to backend database. 
  - SQLusine differs in that we execute no code, we just build the SQL and you can then do what you like with it. 
  - rquery has does have optimizations during SQL rendering, and can create more performant SQL than dplyr. 
  
## Why SQLusine?

`dplyr` and `rquery` are both focused on the ability to do actual data manipulations, and to do so, they had to each build a their own SQL render factory. Package authors who wish to build systems similar to dplyr or rquery must write their own SQL generation factory in addition to a user-facing API. 

The SQL generation factories for `dplyr` and `rquery` are tied very closely to the user-facing API, and as such it is impossible to build off of just those parts of each package. It is my hope that having a package designed just for SQL generation will allow other package authors to build `dplyr` and `rquery` like APIs more easily. 

SQLusine only builds SQL--it doesn't care if column names are accurate or the referenced tables exist. It only attempts to build valid SQL statements, and leaves the rest to the user. This means SQLusine can focus on generating efficient SQL and the users can focus on the application. 


# example use:

``` R
library(SQLusine)
sub_qry <- SELECT(
  from = 'tbl_whatever',
  what = c('k_tbl_whatever', 'name', 'userID', J('department', 'dept_code')),
  inner_join = 'tbl_department',
  on = 'dept_code',
)


qry <- SELECT_DISTINCT(
  from = 'tbl_staff',
  what = c('is_manager', J('name', 'userID', 'department')),
  left_join = sub_qry,
  on = c('dept_code' = J('dept_code'))
)


cat(render_query(sub_qry, conn = DBI::ANSI()))
cat(render_query(qry, conn = DBI::ANSI()))
```

# Optimizers:

### Strip unused columns: `optim_strip_unused_columns`

Iterates through the query tree and removes columns from `what` that are not needed for the final query.

Example: 

```SQL
SELECT t1.col1 
FROM (SELECT * FROM tbl1) as t1
INNER JOIN (SELECT * FROM tbl2) as t2 ON
 t1.col2 = t2.col2
```

becomes

```SQL
SELECT t1.col1
FROM (SELECT col1, col2 FROM tbl1) AS t1
INNER JOIN (SELECT col2 from tbl2) AS t2 ON
  t1.col2 = t2.col2
```

### Refactor as CTE: `optim_refactor_as_cte`

Attempts to detect subqueries that are used more than once in the query and moves them into a common table expressions (if supported by the database).

