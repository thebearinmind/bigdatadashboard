###Test###

library(rJava)
library(AWR.Athena)
library(DBI)
library(shiny)
library(shinyAce)
library(shinyjqui)
library(shinyWidgets)

#con <- AWR.Athena::dbConnect(AWR.Athena::Athena(), region='eu-central-1',
#                        s3_staging_dir='s3://aws-athena-query-results-081365034257-eu-central-1/',
#                        schema_name='my_database')

#dbListTables(con)

#dbGetQuery(con, "select vendor_id, count(vendor_id) from my_database.parquet group by vendor_id")

ui <- fluidPage(
  
  titlePanel("Big Data Dashboard!"),
  
  sidebarLayout(
    sidebarPanel(
      div(class="SQLEditor",
          aceEditor(
            outputId = "sqlEditor", 
            value = "select * from", 
            mode = "sql", 
            theme = "ambiance",
            height = "200px",
            hotkeys = list(
              helpKey = "F1",
              runKey = list(
                win = "Ctrl-R|Ctrl-Shift-Enter",
                mac = "CMD-ENTER|CMD-SHIFT-ENTER"
              )
            )
          ),
          actionButton("runquery", "Run")
      )
    ),
    # Main panel for displaying outputs ----
    mainPanel(
      jqui_draggable(dataTableOutput("tbl")),
      dropdownButton(
        tags$h3("Choose the graph type and parameters"),
        selectInput(inputId = 'xcol', label = 'X Variable', choices = c("A", "B", "C")),
        selectInput(inputId = 'ycol', label = 'Y Variable', choices = c("X", "Y", "Z"), selected = "A"),
        sliderInput(inputId = 'clusters', label = 'Cluster count', value = 3, min = 1, max = 9),
        circle = TRUE, status = "danger", icon = icon("gear"), width = "300px",
        tooltip = tooltipOptions(title = "Click to see inputs !")
      )
    )
  )
)


server <- function(input, output) {
  con=reactiveValues(cc=NULL)
  
  mdl <- modalDialog(
    title = "Please Enter Your Details for Athena Access",
    textInput('region','Region'),
    textInput('stagingdir', 'S3 Staging Directory'),
    textInput('schema', 'Schema'),
    easyClose = T,
    footer = tagList(
      actionButton("run", "Submit")
    )
  )
  
  showModal(mdl)
  
  observeEvent(
    eventExpr = input[["run"]], {
      removeModal()
      con$cc <- AWR.Athena::dbConnect(AWR.Athena::Athena(), region=input$region,
                                   s3_staging_dir=input$stagingdir,
                                   schema_name=input$schema)
    })
  
  #"select * from my_database.parquet limit 10"
  #works, just check how it works with run quesry button.
  df <- eventReactive(eventExpr = input[["runquery"]], {
    tbl <- dbGetQuery(con$cc, input$sqlEditor)
    return(tbl)
  })

  output$tbl <- renderDataTable({
    df()
  }, options = list(scrollX = TRUE,  scrollCollapse = TRUE))
  
}

shinyApp(ui = ui, server = server)