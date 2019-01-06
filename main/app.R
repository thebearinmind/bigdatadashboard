###Main###

library(rJava)
library(AWR.Athena)
library(DBI)
library(shiny)
library(shinyAce)
library(shinyjqui)

ui <- fluidPage(
  
  titlePanel("Big Data Dashboard!"),
  
  sidebarLayout(
    sidebarPanel(
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
    ),
    # Main panel for displaying outputs ----
    mainPanel(
      jqui_draggable(dataTableOutput("tbl"))
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
  
  df <- eventReactive(eventExpr = input[["runquery"]], {
    tbl <- dbGetQuery(con$cc, input$sqlEditor)
  })
  
  output$tbl <- renderDataTable({
    df()
  }, options = list(scrollX = TRUE,  scrollCollapse = TRUE))
  
  
}

shinyApp(ui = ui, server = server)