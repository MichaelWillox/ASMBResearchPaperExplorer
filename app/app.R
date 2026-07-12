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

articles <- articles %>%
 mutate(
  Authors_list  = split_field(Authors),
  Keywords_list = split_field(Keywords)
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
  updateSelectizeInput(session, "title",   choices = sort(unique(df$Title)),                   selected = input$title)
  updateSelectizeInput(session, "author",  choices = sort(unique(unlist(df$Authors_list))),     selected = input$author)
  updateSelectizeInput(session, "keyword", choices = sort(unique(unlist(df$Keywords_list))),    selected = input$keyword)
  updateSelectizeInput(session, "release", choices = sort(unique(df$Release_Date)),              selected = input$release)
 })

 # Results with clickable links
 output$results <- renderDT({
  df <- filtered() %>%
   select(Title, Authors, Keywords, Release_Date, Description, Link)

  df$Link <- paste0('<a href="', df$Link, '" target="_blank">Open</a>')

  datatable(df, escape = FALSE, options = list(pageLength = 10))
 })
}

shinyApp(ui, server)
