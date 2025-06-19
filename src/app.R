library(shiny)
library(DT)

# Get configuration from environment variables
app_secret <- Sys.getenv("APP_SECRET", "default-secret")
port <- as.numeric(Sys.getenv("PORT", "3838"))

# Define UI
ui <- fluidPage(
  titlePanel("R Shiny on Azure Container Apps"),

  # Add some styling
  tags$head(
    tags$style(HTML("
      .content-wrapper {
        margin: 20px;
      }
      .info-box {
        background-color: #f8f9fa;
        border: 1px solid #dee2e6;
        border-radius: 0.375rem;
        padding: 1rem;
        margin-bottom: 1rem;
      }
      .azure-blue {
        color: #0078d4;
      }
    "))
  ),

  div(class = "content-wrapper",
    # Environment info section
    div(class = "info-box",
      h4("🚀 Azure Container Apps Environment", class = "azure-blue"),
      p(paste("Application running on port:", port)),
      p(paste("Environment secret configured:", ifelse(nchar(app_secret) > 0, "✅ Yes", "❌ No"))),
      p(paste("App secret length:", nchar(app_secret), "characters"))
    ),

    # Main application
    sidebarLayout(
      sidebarPanel(
        h4("Data Visualization Controls"),
        sliderInput("obs",
                   "Number of observations:",
                   min = 10,
                   max = 1000,
                   value = 100),

        selectInput("dist_type",
                   "Distribution type:",
                   choices = c("Normal" = "norm",
                             "Uniform" = "unif",
                             "Exponential" = "exp"),
                   selected = "norm"),

        numericInput("seed",
                    "Random seed:",
                    value = 42,
                    min = 1,
                    max = 10000),

        br(),
        actionButton("generate", "Generate New Data", class = "btn-primary"),

        br(), br(),
        div(class = "info-box",
          h5("📊 About this App"),
          p("This R Shiny application demonstrates:"),
          tags$ul(
            tags$li("Azure Container Apps deployment"),
            tags$li("Environment variable configuration"),
            tags$li("Secure secret management"),
            tags$li("Responsive web UI"),
            tags$li("Interactive data visualization")
          )
        )
      ),

      mainPanel(
        tabsetPanel(
          tabPanel("Histogram",
            h4("Data Distribution"),
            plotOutput("distPlot", height = "400px"),
            br(),
            h5("Statistics Summary"),
            verbatimTextOutput("summary")
          ),

          tabPanel("Data Table",
            h4("Generated Data"),
            DT::dataTableOutput("dataTable")
          ),

          tabPanel("System Info",
            h4("System Information"),
            verbatimTextOutput("sysinfo")
          )
        )
      )
    )
  )
)

# Define server logic
server <- function(input, output, session) {
  # Reactive data generation
  data <- eventReactive(input$generate, {
    set.seed(input$seed)

    switch(input$dist_type,
           "norm" = rnorm(input$obs),
           "unif" = runif(input$obs),
           "exp" = rexp(input$obs))
  }, ignoreNULL = FALSE)

  # Initialize data on startup
  observe({
    if (is.null(data())) {
      updateActionButton(session, "generate")
    }
  })

  # Histogram output
  output$distPlot <- renderPlot({
    req(data())

    dist_name <- switch(input$dist_type,
                       "norm" = "Normal",
                       "unif" = "Uniform",
                       "exp" = "Exponential")

    hist(data(),
         breaks = 30,
         col = "#0078d4",
         border = "white",
         main = paste(dist_name, "Distribution"),
         xlab = "Value",
         ylab = "Frequency")
  })

  # Summary statistics
  output$summary <- renderText({
    req(data())
    paste(
      "Count:", length(data()), "\n",
      "Mean:", round(mean(data()), 4), "\n",
      "Std Dev:", round(sd(data()), 4), "\n",
      "Min:", round(min(data()), 4), "\n",
      "Max:", round(max(data()), 4), "\n",
      "Median:", round(median(data()), 4)
    )
  })

  # Data table
  output$dataTable <- DT::renderDataTable({
    req(data())
    data.frame(
      Index = 1:length(data()),
      Value = round(data(), 6)
    )
  }, options = list(pageLength = 15, scrollY = "400px"))

  # System information
  output$sysinfo <- renderText({
    paste(
      "R Version:", R.version.string, "\n",
      "Platform:", R.version$platform, "\n",
      "OS:", Sys.info()["sysname"], "\n",
      "Node Name:", Sys.info()["nodename"], "\n",
      "User:", Sys.info()["user"], "\n",
      "Working Directory:", getwd(), "\n",
      "Session Info:", capture.output(sessionInfo())[1:5], collapse = "\n"
    )
  })
}

# Run the application
shinyApp(ui = ui, server = server)
