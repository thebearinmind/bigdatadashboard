library(shiny)
library(shinyjqui)
library(shinyAce)
library(rJava)
library(AWR.Athena)

# Define UI for app that draws a histogram ----
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
    ),
    width = 12
    ),
    
    jqui_draggable(sidebarPanel(
      
      sliderInput(inputId = "bins",
                  label = "Number of bins:",
                  min = 1,
                  max = 50,
                  value = 30)
      
    ))),
    
    # Main panel for displaying outputs ----
    mainPanel(
      tableOutput("tbl")
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
  
  observeEvent(
    eventExpr = input[["run"]],
    handlerExpr = {
  removeModal()
  #how to render custom object???
  output$tbl <- renderTable({
    con <- AWR.Athena::dbConnect(AWR.Athena::Athena(), region=input$region,
                                 s3_staging_dir=input$stagingdir,
                                 schema_name=input$schema)
    dbGetQuery(con,
      input$sqlEditor)
    })
  })
  
}

shinyApp(ui = ui, server = server)