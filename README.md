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
