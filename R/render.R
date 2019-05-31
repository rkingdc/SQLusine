#'@export
render_query <- function(query, conn){
  UseMethod('render_query', query)
}

render_query.SelectQuery <- function(query, conn){
  select_query_renderer(conn, query)
}

select_query_renderer <- function(conn, query){
  UseMethod('select_query_renderer', conn)
}

select_query_renderer.default <- function(conn, query){
  warning('No S3 generic found. Creating ANSI SQL...')
  select_query_renderer.AnsiConnection(conn, query)
}
