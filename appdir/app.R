library(shiny)
library(tidyverse)
library(DT)  # For interactive tables

# Workaround for Chromium Issue 468227
downloadButton <- function(...) {
 tag <- shiny::downloadButton(...)
 tag$attribs$download <- NULL
 tag
}

# Load the nested data
nested_data <- readRDS("nested_data.RDS")

# Flatten the nested data for dropdown menu generation and filtering
flat_data <- nested_data %>%
  unnest(cols = c(data)) %>% 
  dplyr::select(-Description)
  # mutate(Description = str_trunc(Description, width = 20, side = "right"))


# Define the UI
ui <- fluidPage(
  titlePanel("ASMB Research Paper Explorer"),
  
  sidebarLayout(
    sidebarPanel(
      # Dropdown menus for filtering
      selectInput("journals_periodicals", "Select Journals and Periodicals", choices = c("All", sort(unique(flat_data$Articles_Reports)))),
      selectInput("issue_number", "Select Issue Number", choices = c("All", sort(unique(as.Date(flat_data$Release_Date, format = "%B %d, %Y")), decreasing = TRUE))),
      selectInput("author", "Select Author", choices = c("All", sort(unique(flat_data$Authors)))),
      selectInput("keyword", "Select Keyword", choices = c("All", sort(unique(flat_data$Keywords)))),
      selectInput("release_date", "Select Release Date", 
                  choices = c("All", format(sort(unique(as.Date(flat_data$Release_Date, format = "%B %d, %Y")), decreasing = TRUE), "%B %d, %Y"))),
      selectInput("title", "Select Title", choices = c("All", sort(unique(flat_data$Title)))),
      selectInput("release_type", "Select Release Type", choices = c("All", sort(unique(flat_data$Release_Type)))),
      
      # Checkbox group for selecting displayed columns
      checkboxGroupInput(
        "selected_columns",
        "Select Variables to Display:",
        choices = names(flat_data),
        selected = names(flat_data)
      ),
      
      # Download button
      downloadButton("download_data", "Download Table")
    ),
    
    mainPanel(
      DTOutput("data_table")  # Display the interactive table
    )
  )
)

# Define the server logic
server <- function(input, output, session) {
  
  # Reactive filtering based on dropdown menu selections
  filtered_data <- reactive({
    data <- flat_data
    
    # Apply dropdown filters
    if (input$journals_periodicals != "All") {
      data <- data %>% filter(Articles_Reports == input$journals_periodicals)
    }
    if (input$issue_number != "All") {
      data <- data %>% filter(Issue_Number == input$issue_number)
    }
    if (input$author != "All") {
      data <- data %>% filter(Authors == input$author)
    }
    if (input$keyword != "All") {
      data <- data %>% filter(Keywords == input$keyword)
    }
    if (input$release_date != "All") {
      data <- data %>% filter(Release_Date == input$release_date)
    }
    if (input$title != "All") {
      data <- data %>% filter(Title == input$title)
    }
    if (input$release_type != "All") {
      data <- data %>% filter(Release_Type == input$release_type)
    }
    
    data
  })
  
  # Render the filtered table with expandable rows
  output$data_table <- renderDT({
   datatable(
    filtered_data()[, input$selected_columns, drop = FALSE],  # Subset data by selected columns
    options = list(
     pageLength = 10,           # Number of rows per page
     lengthMenu = c(10, 25, 50), # Row selection options
     autoWidth = TRUE           # Automatically adjust column width
    ),
    rownames = FALSE            # Hide row names
   )
  })
  
  # Allow the user to download the filtered data as a CSV
  output$download_data <- downloadHandler(
    filename = function() {
      paste("ASMB_Papers_", Sys.Date(), ".csv", sep = "")
    },
    content = function(file) {
      write.csv(filtered_data(), file, row.names = FALSE)
    },
    contentType = "text/csv"
  )
}

# Run the app
shinyApp(ui, server)
