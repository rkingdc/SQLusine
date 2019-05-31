
select_query_renderer.AnsiConnection <- function(conn, query){
  # clauses <- c(what = 'SELECT',
  #              from = 'FROM',
  #              join = 'JOIN',
  #              where = 'WHERE',
  #              group_by = 'GROUP BY',
  #              having = 'HAVING',
  #              limit = 'LIMIT')

  ## from
  if (is.character(query$from)){
    from_lhs <- Alias(what = query$from, alias = query$from)
    clause_from <- paste('FROM', DBI::dbQuoteIdentifier(conn, from_lhs$alias))

  } else if (inherits(from, 'Alias')){
    from_lhs <- query$from
    clause_from <- paste('FROM', DBI::dbQuoteIdentifier(conn, from_lhs$what),
                         'AS', DBI::dbQuoteIdentifier(conn, from_lhs$alias))

  } else if (inherits(from, 'SelectQuery')){
    from_lhs <- Alias(what = query$from, alias = random_name())
    clause_from <- paste('FROM (', select_query_renderer(from_lhs$what),
                         ') AS', DBI::dbQuoteIdentifier(conn, from_lhs$alias))
  }

  if (!is.null(query$join)){
    if (is.character(query$join$from)){
      from_rhs <- Alias(what = query$join$from, alias = query$join$from)
      join_from_clause <- DBI::dbQuoteIdentifier(conn, from_rhs$alias)
    }
    if (inherits(query$join$from, 'Alias')){
      from_rhs <- Alias(what = query$join$from)
      join_from_clause <- paste(DBI::dbQuoteIdentifier(conn, from_rhs$what),
                                'AS', DBI::dbQuoteIdentifier(conn, from_rhs$alias))
    }
    if (inherits(query$join$from, 'SelectQuery')){
      from_rhs <- Alias(what = query$join$from, alias = random_name())
      join_from_clause <- paste('(', render_query(from_rhs$what, conn=conn),
                                ') AS', DBI::dbQuoteIdentifier(conn, from_rhs$alias))
    }
    join_stmt <- switch(query$join$type,
                        'inner' = 'INNER JOIN',
                        'left' = 'LEFT JOIN',
                        'right' = 'RIGHT JOIN')
    on_stmt <- paste0(DBI::dbQuoteIdentifier(conn, from_lhs$alias), '.',
                      DBI::dbQuoteIdentifier(conn, extract_lhs_on(query$join$on)),
                      ' = ',
                      DBI::dbQuoteIdentifier(conn, from_rhs$alias), '.',
                      DBI::dbQuoteIdentifier(conn, extract_rhs_on(query$join$on)))
    clause_join <- paste(join_stmt, join_from_clause, 'ON', on_stmt)

  } else {
    clause_join <- NULL
  }

  ## select
  select_keyword <- switch(query$type,
                           select = 'SELECT',
                           distinct = 'SELECT DISTINCT')

  if (length(query$what) == 1 && query$what == '*') {
    clause_select <- paste(select_keyword, '*')
  } else {
    from_column_labels <- vapply(query$what, function(x){
      if (!is.null(attr(x, 'source')) && attr(x, 'source') == 'join'){
        from_rhs$alias
      } else {
        from_lhs$alias
      }
    }, FUN.VALUE = character(1))

    column_labels <- paste(
      DBI::dbQuoteIdentifier(conn=conn, x = from_column_labels), '.',
      DBI::dbQuoteIdentifier(conn=conn, x = extract_identifiers(query$what)),
      sep=''
    )

    clause_select <- sprintf('%s %s',select_keyword, paste(column_labels, collapse=', '))

  }

  paste(clause_select,
        clause_from,
        clause_join, sep='\n')
}
