library(rJava)
library(AWR.Athena)
library(DBI)
library(shiny)

#con <- AWR.Athena::dbConnect(AWR.Athena::Athena(), region='eu-central-1',
#                        s3_staging_dir='s3://aws-athena-query-results-081365034257-eu-central-1/',
#                        schema_name='my_database')

#dbListTables(con)

#dbGetQuery(con, "select vendor_id, count(vendor_id) from my_database.parquet group by vendor_id")

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
      )
      ),
    # Main panel for displaying outputs ----
    mainPanel(
      dataTableOutput("tbl")
    )
  )
)
  
  
server <- function(input, output) {
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
  
  dbcon <- eventReactive(
    eventExpr = input[["run"]], {
      removeModal()
      con <- AWR.Athena::dbConnect(AWR.Athena::Athena(), region=input$region,
                                     s3_staging_dir=input$stagingdir,
                                     schema_name=input$schema)
      return(con)
      })
  #"select * from my_database.parquet limit 10"
  #works, just check how it works with run quesry button.
  output$tbl <- renderDataTable({
    dbGetQuery(dbcon(), input$sqlEditor)
  })

}

shinyApp(ui = ui, server = server)