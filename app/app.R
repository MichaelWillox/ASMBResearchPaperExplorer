library(shiny)
library(dplyr)
library(DT)

# Load your prepared dataset
articles_long <- readRDS("esr_articles_shiny.rds")

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
 
 # Reactive dataset
 filtered <- reactive({
  df <- articles_long
  if (length(input$title))   df <- df %>% filter(Title %in% input$title)
  if (length(input$author))  df <- df %>% filter(Authors %in% input$author)
  if (length(input$keyword)) df <- df %>% filter(Keywords %in% input$keyword)
  if (length(input$release)) df <- df %>% filter(Release_Date %in% input$release)
  df
 })
 
 # Update dropdown menus dynamically
 observe({
  df <- filtered()
  updateSelectizeInput(session, "title",   choices = sort(unique(df$Title)),        selected = input$title)
  updateSelectizeInput(session, "author",  choices = sort(unique(df$Authors)),      selected = input$author)
  updateSelectizeInput(session, "keyword", choices = sort(unique(df$Keywords)),     selected = input$keyword)
  updateSelectizeInput(session, "release", choices = sort(unique(df$Release_Date)), selected = input$release)
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
