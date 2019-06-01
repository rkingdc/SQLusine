
.ansi_join <- function(from_lhs, from_rhs, join, join_from_clause, conn){

  join_stmt <- switch(join$type,
                      'inner' = 'INNER JOIN',
                      'left' = 'LEFT JOIN',
                      'right' = 'RIGHT JOIN')

  on_stmt <- paste0(DBI::dbQuoteIdentifier(conn, from_lhs$alias), '.',
                    DBI::dbQuoteIdentifier(conn, extract_lhs_on(join$on)),
                    ' = ',
                    DBI::dbQuoteIdentifier(conn, from_rhs$alias), '.',
                    DBI::dbQuoteIdentifier(conn, extract_rhs_on(join$on)))
  clause_join <- paste(join_stmt, join_from_clause, 'ON', on_stmt)
  return (clause_join)
}


.ansi_column_source <- function(what, from_rhs, from_lhs){

  if (length(what) == 1 && what == '*') {
    return(NULL)
  }

    vapply(what, function(x){
      if (!is.null(attr(x, 'source')) && attr(x, 'source') == 'join'){
        from_rhs$alias
      } else {
        from_lhs$alias
      }
    }, FUN.VALUE = character(1))
}

.ansi_select <- function(type, column_sources, column_identifiers, conn){
  select_keyword <- switch(query$type,
                           select = 'SELECT',
                           distinct = 'SELECT DISTINCT')

  if (length(column_identifiers) == 1 && column_identifiers == '*'){
    column_labels <- '*'
  } else {
    column_labels <- paste(
      DBI::dbQuoteIdentifier(conn=conn, x = column_sources), '.',
      DBI::dbQuoteIdentifier(conn=conn, x = column_identifiers),
      sep=''
    )
  }

  clause_select <- sprintf('%s %s',select_keyword, paste(column_labels, collapse=', '))
  return (clause_select)
}

select_query_renderer.AnsiConnection <- function(conn, query){
  # what = 'SELECT',
  # from = 'FROM',
  # join = 'JOIN',
  # where = 'WHERE',
  # group_by = 'GROUP BY',
  # having = 'HAVING',
  # limit = 'LIMIT')

  ### FROM ###
  from_list   <- .from(from = query$from, conn=conn)
  from_lhs    <- from_list$from_alias
  clause_from <- paste('FROM', from_list$clause_from)

  ### JOIN ###
  if(!is.null(query$join)){

    # determining join source is same procces as FROM above
    join_from_list   <- .from(from = query$join$from, conn=conn)
    from_rhs         <- join_from_list$from_alias
    join_from_clause <- join_from_list$clause_from

    # then we add join-specific syntax
    clause_join <- .ansi_join(
      from_lhs = from_lhs,
      from_rhs = from_rhs,
      join = query$join,
      join_from_clause = join_from_clause,
      conn = conn)

  } else {
    clause_join <- NULL
  }

  ### SELECT ###
  select_column_source <- .ansi_column_source(what = query$what,
                                              from_lhs = from_lhs,
                                              from_rhs = from_rhs)
  select_column_identifier <- extract_identifiers(query$what)

  clause_select <- .ansi_select(type = query$type,
                                column_sources = select_column_source,
                                column_identifiers = select_column_identifier,
                                conn = conn)


  paste(clause_select,
        clause_from,
        clause_join, sep='\n')
}
