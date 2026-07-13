library(shiny)
library(dplyr)
library(DT)

# Load the prepared dataset: one row per article. Authors and Keywords are
# semicolon-joined strings (e.g. "Smith, J.; Doe, A."), split into list-
# columns below so users can still search/filter on an individual author or
# keyword without the underlying rows being duplicated per combination.
articles <- readRDS("asmb_articles.rds")

split_field <- function(x) {
 lapply(strsplit(x, "\\s*;\\s*"), function(v) v[!is.na(v) & nzchar(v)])
}

# Release_Date is stored as text like "March 30, 2026", so DT's default
# column sort treats it as a string and orders it alphabetically (e.g.
# "April ..." sorts before "January ..."). Parse it into a real Date -
# using month.name for lookup instead of a locale-dependent %B format,
# since this app also runs inside webR in the browser, where the date
# locale can't be relied on - and keep it as a hidden numeric sort key so
# the table can be ordered chronologically while still displaying the
# original, readable text.
parse_release_date <- function(x) {
 pieces <- regmatches(x, regexec("^([A-Za-z]+) ([0-9]{1,2}), ([0-9]{4})$", x))
 iso <- vapply(pieces, function(p) {
  if (length(p) != 4) return(NA_character_)
  mon <- match(p[2], month.name)
  if (is.na(mon)) return(NA_character_)
  sprintf("%04d-%02d-%02d", as.integer(p[4]), mon, as.integer(p[3]))
 }, character(1))
 as.Date(iso)
}

articles <- articles %>%
 mutate(
  Authors_list      = split_field(Authors),
  Keywords_list     = split_field(Keywords),
  Release_Date_sort = as.numeric(parse_release_date(Release_Date))
 )

ui <- fluidPage(
 titlePanel("ASMB Research Paper Explorer"),

 sidebarLayout(
  sidebarPanel(
   selectizeInput("title",   "Select Title(s):",   choices = NULL, multiple = TRUE),
   selectizeInput("author",  "Select Author(s):",  choices = NULL, multiple = TRUE),
   selectizeInput("keyword", "Select Keyword(s):", choices = NULL, multiple = TRUE),
   selectizeInput("release", "Select Release Date(s):", choices = NULL, multiple = TRUE)
  ),

  mainPanel(
   DTOutput("results")
  )
 )
)

server <- function(input, output, session) {

 # Reactive dataset. An article matches an author/keyword filter if that
 # author/keyword appears anywhere in its (unexploded) list of authors or
 # keywords - so multi-author, multi-keyword articles still show up under
 # each individual search term, but only ever as a single row.
 filtered <- reactive({
  df <- articles
  if (length(input$title))   df <- df %>% filter(Title %in% input$title)
  if (length(input$author))  df <- df %>% filter(sapply(Authors_list,  function(a) any(a %in% input$author)))
  if (length(input$keyword)) df <- df %>% filter(sapply(Keywords_list, function(k) any(k %in% input$keyword)))
  if (length(input$release)) df <- df %>% filter(Release_Date %in% input$release)
  df
 })

 # Update dropdown menus dynamically
 observe({
  df <- filtered()

  # Order the Release Date choices chronologically (oldest/newest by the
  # parsed date), not alphabetically by the display text.
  release_choices <- df %>%
   distinct(Release_Date, Release_Date_sort) %>%
   arrange(Release_Date_sort) %>%
   pull(Release_Date)

  updateSelectizeInput(session, "title",   choices = sort(unique(df$Title)),                 selected = input$title)
  updateSelectizeInput(session, "author",  choices = sort(unique(unlist(df$Authors_list))),  selected = input$author)
  updateSelectizeInput(session, "keyword", choices = sort(unique(unlist(df$Keywords_list))), selected = input$keyword)
  updateSelectizeInput(session, "release", choices = release_choices,                        selected = input$release)
 })

 # Results with clickable links
 output$results <- renderDT({
  df <- filtered() %>%
   select(Title, Authors, Keywords, Release_Date, Description, Link, Citation, Release_Date_sort)

  df$Link <- paste0('<a href="', df$Link, '" target="_blank">Open</a>')

  datatable(
   df,
   escape = FALSE,
   rownames = FALSE,
   options = list(
    pageLength = 10,
    columnDefs = list(
     list(visible = FALSE, targets = 7),  # hide the Release_Date_sort key
     list(orderData = 7,   targets = 3)   # but sort Release_Date by it
    )
   )
  )
 })
}

shinyApp(ui, server)
