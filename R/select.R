random_name <- function(n=9, prefix='sqlusine_'){
  paste0(prefix, paste(sample(letters, size=n, replace=TRUE), collapse=''), sep='')
}

#' @export
J <- function(...){
  lapply(list(...), function(x) {
    attr(x, 'source') <- 'join'
    x
  })
}

#'@export
Alias <- function(what, alias=NULL){
  if(is.null(alias)){
    alias <- random_name()
  }
  al <- list(what = what,
             alias = alias)
  class(al) <- c('Alias', 'list')
  al
}

#'@export
`%AS%` <- Alias

#'@export
SELECT <- function(from,
                   what='*',
                   inner_join = NULL,
                   left_join = NULL,
                   right_join = NULL,
                   on = NULL,
                   where = NULL,
                   group_by = NULL,
                   having = NULL,
                   limit = NULL){
  .select(type = 'select',
          from=from,
          what=what,
          inner_join = inner_join,
          left_join = left_join,
          right_join = right_join,
          on = on,
          where = where,
          group_by = group_by,
          having = having,
          limit = limit)
}

#'@export
SELECT_DISTINCT <- function(from,
                   what='*',
                   inner_join = NULL,
                   left_join = NULL,
                   right_join = NULL,
                   on = NULL,
                   where = NULL,
                   group_by = NULL,
                   having = NULL,
                   limit = NULL){
  .select(type = 'distinct',
          from=from,
          what=what,
          inner_join = inner_join,
          left_join = left_join,
          right_join = right_join,
          on = on,
          where = where,
          group_by = group_by,
          having = having,
          limit = limit)
}



.select <- function(type = 'select',
                    from,
                    what='*',
                    inner_join = NULL,
                    left_join = NULL,
                    right_join = NULL,
                    on = NULL,
                    where = NULL,
                    group_by = NULL,
                    having = NULL,
                    limit = NULL){

  if(sum(!c(is.null(inner_join), is.null(left_join), is.null(right_join))) > 1){
    stop('Only one of join, left_join, and right_join are allowed')
  }


  if (!is.null(inner_join)){
    join <- list(type = 'inner', from = inner_join, on = on)
  } else if (!is.null(left_join)){
    join <- list(type = 'left', from = left_join, on = on)
  } else if (!is.null(right_join)){
    join <- list(type = 'right', from = left_join, on = on)
  } else {
    join <- NULL
  }

  sel_qry <- list(type = type,
                  from = from,
                  what = what,
                  join = join,
                  where = where,
                  group_by = group_by,
                  having = having,
                  limit = limit)

  class(sel_qry) <- c('SelectQuery', 'list')
  return(sel_qry)
}


extract_identifiers <- function(x){
  ids <- lapply(x, function(xx){
    if(inherits(xx, 'Alias')){
      xx$alias
    } else if (is.list(xx)){
      extract_identifiers(xx)
    } else {
      unlist(xx)
    }
  })
  unname(unlist(ids))
}

extract_lhs_on <- function(on){

  if (is.null(names(on))){
    return(on)
  }

  lhs <- names(on)
  lhs[lhs == ''] <- on[lhs=='']
  unlist(lhs)
}

extract_rhs_on <- function(on){
  extract_identifiers(on)
}

