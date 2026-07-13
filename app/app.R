library(shiny)
library(dplyr)
library(DT)

# Workaround for Chromium Issue 468227
downloadButton <- function(...) {
 tag <- shiny::downloadButton(...)
 tag$attribs$download <- NULL
 tag
}

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
 tags$head(
  tags$style(HTML("
   #results table { table-layout: fixed; width: 100%; }
   #results td { overflow: hidden; }
  "))
 ),
 titlePanel("ASMB Research Paper Explorer"),

 sidebarLayout(
  sidebarPanel(
   selectizeInput("title",   "Select Title(s):",   choices = NULL, multiple = TRUE),
   selectizeInput("author",  "Select Author(s):",  choices = NULL, multiple = TRUE),
   selectizeInput("keyword", "Select Keyword(s):", choices = NULL, multiple = TRUE),
   selectizeInput("release", "Select Release Date(s):", choices = NULL, multiple = TRUE),
   tags$hr(),
   helpText("Click a row to select it (ctrl/cmd-click or shift-click for ",
            "more than one), then download the full, untruncated details ",
            "for just those papers. If nothing is selected, everything ",
            "currently shown below is downloaded instead."),
   downloadButton("download_selected", "Download selected papers")
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

 # The exact table shown to the user, in the same row order used both for
 # rendering and for row-selection indices, so a selected row number
 # always maps back to the correct, full (untruncated) record - DT keeps
 # selection indices tied to this original row order regardless of
 # whatever sorting/searching the user does in the browser.
 table_data <- reactive({
  filtered() %>%
   select(Title, Authors, Keywords, Release_Date, Description, Link, Citation, Release_Date_sort)
 })

 # Keywords, Description, and Citation are long free text. DataTables
 # wraps long cell text onto multiple lines by default, which stretches
 # every row's height and shrinks how many results fit on screen at
 # once. Truncate each to a single line with an ellipsis, and keep the
 # full text available as a native tooltip (title attribute) on hover -
 # and, for anyone who needs to copy the full text, via the download
 # button below.
 truncate_with_tooltip <- function(x) {
  safe    <- ifelse(is.na(x), "", x)
  tooltip <- gsub('"', "&quot;", safe, fixed = TRUE)
  sprintf(
   '<div style="white-space:nowrap; overflow:hidden; text-overflow:ellipsis;" title="%s">%s</div>',
   tooltip, safe
  )
 }

 # Results with clickable links
 output$results <- renderDT({
  df <- table_data()

  df$Link        <- paste0('<a href="', df$Link, '" target="_blank">Open</a>')
  df$Keywords    <- truncate_with_tooltip(df$Keywords)
  df$Description <- truncate_with_tooltip(df$Description)
  df$Citation    <- truncate_with_tooltip(df$Citation)

  datatable(
   df,
   escape = FALSE,
   rownames = FALSE,
   selection = list(mode = "multiple", target = "row"),
   options = list(
    pageLength = 15,
    autoWidth = TRUE,
    columnDefs = list(
     list(visible = FALSE, targets = 7),   # hide the Release_Date_sort key
     list(orderData = 7,   targets = 3),   # but sort Release_Date by it
     list(width = "16%", targets = 0),     # Title
     list(width = "10%", targets = 1),     # Authors
     list(width = "10%", targets = 2),     # Keywords
     list(width = "7%",  targets = 3),     # Release_Date
     list(width = "20%", targets = 4),     # Description
     list(width = "4%",  targets = 5),     # Link
     list(width = "20%", targets = 6)      # Citation
    )
   )
  )
 })

 # Download the full, untruncated details for the selected rows (or, if
 # nothing is selected, for everything currently shown by the filters).
 output$download_selected <- downloadHandler(
  filename = function() paste0("asmb_articles_", Sys.Date(), ".csv"),
  content = function(file) {
   full     <- table_data() %>% select(-Release_Date_sort)
   selected <- input$results_rows_selected
   out <- if (length(selected)) full[selected, , drop = FALSE] else full
   write.csv(out, file, row.names = FALSE, na = "")
  }
 )
}

shinyApp(ui, server)
