# ============================================================
# WAREHOUSE ENVIRONMENTAL MONITORING
# Shiny Visualization App
# ============================================================

library(shiny)
library(dplyr)
library(plotly)
library(viridisLite)


# ============================================================
# SETTINGS
# ============================================================

data_folder <- "Processed_Data"


# ============================================================
# LOAD ALL PROCESSED CSV FILES
# ============================================================

csv_files <- list.files(
  path = data_folder,
  pattern = "\\.csv$",
  full.names = TRUE
)


# Stop if no files are found

if (length(csv_files) == 0) {
  
  stop(
    "No processed CSV files were found in: ",
    data_folder
  )
  
}


# ============================================================
# READ PROCESSED FILES
# ============================================================

processed_data <- lapply(
  
  csv_files,
  
  function(file) {
    
    df <- read.csv(
      file,
      stringsAsFactors = FALSE
    )
    
    df$Timestamp <- as.POSIXct(
      df$Timestamp,
      tz = "UTC"
    )
    
    df
    
  }
  
)


# Use filenames as experiment names

experiment_names <- tools::file_path_sans_ext(
  basename(csv_files)
)


names(processed_data) <- experiment_names


# ============================================================
# UI
# ============================================================

ui <- fluidPage(
  
  titlePanel(
    "Warehouse Environmental Monitoring"
  ),
  
  tabsetPanel(
    
    id = "experiment_tab",
    
    lapply(
      
      experiment_names,
      
      function(experiment) {
        
        data <- processed_data[[experiment]]
        
        tabPanel(
          
          title = experiment,
          
          sidebarLayout(
            
            sidebarPanel(
              
              # ------------------------------------------------
              # TIMEPOINT
              # ------------------------------------------------
              
              selectInput(
                
                inputId =
                  paste0(
                    "time_",
                    experiment
                  ),
                
                label =
                  "Timepoint",
                
                choices =
                  sort(
                    unique(
                      data$Timestamp
                    )
                  ),
                
                selected =
                  min(
                    data$Timestamp
                  )
                
              ),
              
              
              # ------------------------------------------------
              # ENVIRONMENTAL VARIABLE
              # ------------------------------------------------
              
              selectInput(
                
                inputId =
                  paste0(
                    "variable_",
                    experiment
                  ),
                
                label =
                  "Environmental Variable",
                
                choices = c(
                  
                  "Temperature (°F)" =
                    "Predicted_Temperature_F",
                  
                  "Relative Humidity (%)" =
                    "Predicted_Relative_Humidity_pct",
                  
                  "Dew Point (°F)" =
                    "Predicted_Dew_Point_F",
                  
                  "Dew Point Depression (°F)" =
                    "Predicted_Dew_Point_Depression_F"
                  
                ),
                
                selected =
                  "Predicted_Temperature_F"
                
              )
              
            ),
            
            mainPanel(
              
              plotlyOutput(
                
                outputId =
                  paste0(
                    "plot_",
                    experiment
                  ),
                
                height = "750px"
                
              )
              
            )
            
          )
          
        )
        
      }
      
    )
    
  )
  
)


# ============================================================
# SERVER
# ============================================================

server <- function(
    
  input,
  output,
  session
  
) {
  
  
  # ==========================================================
  # CREATE PLOT FOR EACH EXPERIMENT
  # ==========================================================
  
  for (
    
    experiment in experiment_names
    
  ) {
    
    local({
      
      exp_name <- experiment
      
      # ------------------------------------------------------
      # Experiment data
      # ------------------------------------------------------
      
      experiment_data <-
        processed_data[[exp_name]]
      
      
      # ------------------------------------------------------
      # Render Plot
      # ------------------------------------------------------
      
      output[[
        
        paste0(
          "plot_",
          exp_name
        )
        
      ]] <- renderPlotly({
        
        # ----------------------------------------------------
        # Selected controls
        # ----------------------------------------------------
        
        selected_time <-
          
          input[[
            
            paste0(
              "time_",
              exp_name
            )
            
          ]]
        
        
        selected_variable <-
          
          input[[
            
            paste0(
              "variable_",
              exp_name
            )
            
          ]]
        
        
        # ----------------------------------------------------
        # Selected spatial field
        # ----------------------------------------------------
        
        plot_data <-
          
          experiment_data %>%
          
          filter(
            
            Timestamp ==
              selected_time
            
          )
        
        
        # ----------------------------------------------------
        # Determine colorbar title
        # ----------------------------------------------------
        
        variable_label <-
          
          switch(
            
            selected_variable,
            
            Predicted_Temperature_F =
              "Temperature (°F)",
            
            Predicted_Relative_Humidity_pct =
              "Relative Humidity (%)",
            
            Predicted_Dew_Point_F =
              "Dew Point (°F)",
            
            Predicted_Dew_Point_Depression_F =
              "Dew Point Depression (°F)"
            
          )
        
        
        # ----------------------------------------------------
        # Room dimensions
        # ----------------------------------------------------
        
        room_length <-
          max(
            plot_data$X_ft,
            na.rm = TRUE
          )
        
        room_width <-
          max(
            plot_data$Y_ft,
            na.rm = TRUE
          )
        
        room_height <-
          max(
            plot_data$Z_ft,
            na.rm = TRUE
          )
        
        
        # ----------------------------------------------------
        # 3D interpolated field
        # ----------------------------------------------------
        
        P <- plot_ly(
          
          data = plot_data,
          
          x = ~X_ft,
          y = ~Y_ft,
          z = ~Z_ft,
          
          type = "scatter3d",
          mode = "markers",
          
          marker = list(
            
            size = 10,
            
            opacity = 0.15,
            
            symbol = "square",
            
            color =
              plot_data[[selected_variable]],
            
            colorscale = "Viridis",
            
            colorbar = list(
              
              title = list(
                text =
                  variable_label
              ),
              
              x = 1.12
              
            )
            
          ),
          
          hoverinfo = "none",
          
          name = "Estimated Values"
          
        )
        
        
        # ----------------------------------------------------
        # Actual sensor locations
        # ----------------------------------------------------
        
        # Sensor data will be added here once we retain
        # the sensor observations in the processed output.
        
        
        # ----------------------------------------------------
        # Layout
        # ----------------------------------------------------
        
        P %>%
          
          layout(
            
            scene = list(
              
              xaxis = list(
                title = "Length (ft)",
                range =
                  c(
                    0,
                    room_length
                  )
              ),
              
              yaxis = list(
                title = "Width (ft)",
                range =
                  c(
                    0,
                    room_width
                  )
              ),
              
              zaxis = list(
                title = "Height (ft)",
                range =
                  c(
                    0,
                    room_height
                  )
              ),
              
              aspectmode = "data"
              
            ),
            
            legend = list(
              
              x = 0.01,
              
              y = 0.99,
              
              xanchor = "left",
              
              yanchor = "top"
              
            ),
            
            title = paste(
              exp_name,
              "—",
              variable_label
            )
            
          )
        
      })
      
    })
    
  }
  
}


# ============================================================
# RUN APP
# ============================================================

shinyApp(
  ui = ui,
  server = server
)