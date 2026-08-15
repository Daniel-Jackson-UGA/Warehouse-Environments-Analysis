## ============================================================
# WAREHOUSE ENVIRONMENTAL MONITORING
# Shiny Visualization App
# ============================================================


# ============================================================
# 1. LOAD PACKAGES
# ============================================================

library(shiny)
library(dplyr)
library(plotly)
library(viridisLite)


# ============================================================
# 2. DEFINE DATA FOLDER
# ============================================================

data_folder <-
  "C:/Users/Daniel Jackson/Desktop/R/Warehouse Environments Analysis/Processed_Data"


# ============================================================
# 3. FIND ALL EXPERIMENT FILES
# ============================================================

processed_files <- list.files(
  
  path = data_folder,
  
  pattern = "_processed_data\\.csv$",
  
  full.names = TRUE
  
)


sensor_files <- list.files(
  
  path = data_folder,
  
  pattern = "_sensor_data\\.csv$",
  
  full.names = TRUE
  
)


metadata_files <- list.files(
  
  path = data_folder,
  
  pattern = "_metadata\\.csv$",
  
  full.names = TRUE
  
)


# ============================================================
# 3.1 EXTRACT EXPERIMENT NAMES
# ============================================================

processed_experiments <- sub(
  
  "_processed_data\\.csv$",
  
  "",
  
  basename(processed_files)
  
)


sensor_experiments <- sub(
  
  "_sensor_data\\.csv$",
  
  "",
  
  basename(sensor_files)
  
)


metadata_experiments <- sub(
  
  "_metadata\\.csv$",
  
  "",
  
  basename(metadata_files)
  
)


# ============================================================
# 3.2 KEEP ONLY COMPLETE EXPERIMENTS
# ============================================================

experiment_names <- Reduce(
  
  intersect,
  
  list(
    
    processed_experiments,
    
    sensor_experiments,
    
    metadata_experiments
    
  )
  
)


# ============================================================
# 3.3 VERIFY EXPERIMENTS
# ============================================================

if (length(experiment_names) == 0) {
  
  stop(
    
    paste(
      
      "No complete experiment file sets were found in:",
      
      data_folder
      
    )
    
  )
  
}


# Sort experiments

experiment_names <-
  sort(experiment_names)


cat(
  "\nExperiments found:\n"
)

print(
  experiment_names
)


# ============================================================
# 4. CREATE EXPERIMENT IDENTIFIERS
# ============================================================

# These IDs are used internally by Shiny.
# They are kept separate from the visible experiment names.

experiment_ids <-
  setNames(
    
    paste0(
      "exp_",
      seq_along(experiment_names)
    ),
    
    experiment_names
    
  )


# ------------------------------------------------------------
# Function for displaying experiment names
# ------------------------------------------------------------

display_experiment_name <- function(x) {
  
  x %>%
    
    gsub(
      "_",
      " ",
      .
    )
  
}


# ============================================================
# 5. LOAD ALL PROCESSED ENVIRONMENTAL DATA
# ============================================================

processed_data_list <- lapply(
  
  experiment_names,
  
  function(experiment) {
    
    file <- file.path(
      
      data_folder,
      
      paste0(
        experiment,
        "_processed_data.csv"
      )
      
    )
    
    
    df <- read.csv(
      
      file,
      
      stringsAsFactors = FALSE
      
    )
    
    
    df$Timestamp <-
      as.POSIXct(
        df$Timestamp,
        tz = "UTC"
      )
    
    
    df
    
  }
  
)


names(processed_data_list) <-
  experiment_names


# ============================================================
# 6. LOAD ALL SENSOR DATA
# ============================================================

sensor_data_list <- lapply(
  
  experiment_names,
  
  function(experiment) {
    
    file <- file.path(
      
      data_folder,
      
      paste0(
        experiment,
        "_sensor_data.csv"
      )
      
    )
    
    
    df <- read.csv(
      
      file,
      
      stringsAsFactors = FALSE
      
    )
    
    
    df$Timestamp <-
      as.POSIXct(
        df$Timestamp,
        tz = "UTC"
      )
    
    
    df
    
  }
  
)


names(sensor_data_list) <-
  experiment_names


# ============================================================
# 6.1 LOAD ALL EXPERIMENT METADATA
# ============================================================

metadata_list <- lapply(
  
  experiment_names,
  
  function(experiment) {
    
    file <- file.path(
      
      data_folder,
      
      paste0(
        
        experiment,
        
        "_metadata.csv"
        
      )
      
    )
    
    
    metadata <- read.csv(
      
      file,
      
      stringsAsFactors = FALSE
      
    )
    
    
    metadata
    
  }
  
)


names(metadata_list) <-
  experiment_names

# ============================================================
# 6.2 METADATA HELPER FUNCTION
# ============================================================

get_metadata_value <- function(
    
  metadata,
  
  parameter
  
) {
  
  value <-
    
    metadata$Value[
      metadata$Parameter == parameter
    ]
  
  
  if (length(value) == 0) {
    
    return(NA)
    
  }
  
  
  value[[1]]
  
}

# ============================================================
# 7. CHECK DATA
# ============================================================

for (experiment in experiment_names) {
  
  cat(
    "\n----------------------------------------\n"
  )
  
  cat(
    "Experiment:",
    experiment,
    "\n"
  )
  
  cat(
    "Processed rows:",
    nrow(
      processed_data_list[[experiment]]
    ),
    "\n"
  )
  
  cat(
    "Sensor rows:",
    nrow(
      sensor_data_list[[experiment]]
    ),
    "\n"
  )
  
}


# ============================================================
# 8. ENVIRONMENTAL VARIABLES
# ============================================================

environmental_variables <- c(
  
  "Temperature (°F)" =
    "Predicted_Temperature_F",
  
  "Relative Humidity (%)" =
    "Predicted_Relative_Humidity_pct",
  
  "Dew Point (°F)" =
    "Predicted_Dew_Point_F",
  
  "Dew Point Depression (°F)" =
    "Predicted_Dew_Point_Depression_F"
  
)


# ============================================================
# 9. DEFINE TIMEPOINTS FOR EACH EXPERIMENT
# ============================================================

timepoints_list <- lapply(
  
  processed_data_list,
  
  function(df) {
    
    sort(
      unique(
        df$Timestamp
      )
    )
    
  }
  
)


names(timepoints_list) <-
  experiment_names


# ============================================================
# 10. USER INTERFACE
# ============================================================


# ============================================================
# 10.1 CREATE EXPERIMENT TAB UI
# ============================================================

experiment_tabs <- lapply(
  
  experiment_names,
  
  function(experiment) {
    
    id <- experiment_ids[[experiment]]
    
    variable_id <-
      paste0(
        "variable_",
        id
      )
    
    time_id <-
      paste0(
        "time_",
        id
      )
    
    plot_id <-
      paste0(
        "plot_",
        id
      )
    
    time_display_id <-
      paste0(
        "time_display_",
        id
      )
    
    
    tabPanel(
      
      title =
        display_experiment_name(
          experiment
        ),
      
      
      sidebarLayout(
        
        
        # ====================================================
        # 10.2 SIDEBAR
        # ====================================================
        
        sidebarPanel(
          
          selectInput(
            
            inputId =
              variable_id,
            
            label =
              "Environmental Variable",
            
            choices =
              environmental_variables,
            
            selected =
              "Predicted_Temperature_F"
            
          )
          
        ),
        
        
        # ====================================================
        # 10.3 MAIN PANEL
        # ====================================================
        
        mainPanel(
          
          
          plotlyOutput(
            
            outputId =
              plot_id,
            
            height =
              "550px"
            
          ),
          
          
          br(),
          
          
          # --------------------------------------------------
          # Selected time
          # --------------------------------------------------
          
          h5(
            
            textOutput(
              time_display_id
            )
            
          ),
          
          
          # --------------------------------------------------
          # TIME SLIDER + PLAY BUTTON
          # --------------------------------------------------
          
          fluidRow(
            
            column(
              
              width = 10,
              
              sliderInput(
                
                inputId =
                  time_id,
                
                label =
                  NULL,
                
                min =
                  1,
                
                max =
                  length(
                    timepoints_list[[experiment]]
                  ),
                
                value =
                  1,
                
                step =
                  1,
                
                ticks =
                  TRUE,
                
                width =
                  "100%"
                
              )
              
            ),
            
            column(
              
              width = 2,
              
              actionButton(
                
                inputId =
                  paste0(
                    "play_",
                    id
                  ),
                
                label =
                  "▶ Play",
                
                class =
                  "btn-primary",
                
                width =
                  "100%"
                
              )
              
            )
            
          )
          
        )  # mainPanel
        
      )    # sidebarLayout
      
    )      # tabPanel
    
  }
  
)

# ============================================================
# 10.4 MAIN UI
# ============================================================

ui <- fluidPage(
  
  
  tags$head(
    
    tags$style(HTML("

      /* -----------------------------------------------
         Overall browser background
         ----------------------------------------------- */

      body {
        background-color: #F5F8F7;
      }


      /* -----------------------------------------------
         Main application container
         ----------------------------------------------- */

      .container-fluid {
        max-width: 1400px;
        margin: auto;
      }


      /* -----------------------------------------------
         Timepoint display
         ----------------------------------------------- */

      .time-display {
        font-size: 20px;
        font-weight: bold;
      }


      /* -----------------------------------------------
         Time slider
         ----------------------------------------------- */

      .irs-min,
      .irs-max,
      .irs-from,
      .irs-to,
      .irs-single {

        font-size: 18px !important;

        font-weight: bold !important;

      }


      .irs-grid-text {

        font-size: 16px !important;

        font-weight: bold !important;

      }

    "))
    
  ),
  
  
  # ========================================================
  # APPLICATION TITLE
  # ========================================================
  
  titlePanel(
    
    h2(
      
      "Warehouse Environmental Monitoring",
      
      style = "

        font-weight: bold;

        font-size: 32px;

      "
      
    )
    
  ),
  
  
  # ========================================================
  # EXPERIMENT TABS
  # ========================================================
  
  do.call(
    
    tabsetPanel,
    
    c(
      
      list(
        id = "experiment_tab"
      ),
      
      experiment_tabs
      
    )
    
  )
  
)


# ============================================================
# 11. SERVER
# ============================================================

server <- function(
    
  input,
  
  output,
  
  session
  
) {
  
  
  # ============================================================
  # 11.1 CREATE OUTPUTS FOR EACH EXPERIMENT
  # ============================================================
  
  lapply(
    
    experiment_names,
    
    function(experiment) {
      
      local({
        
        current_experiment <-
          experiment
        
        
        current_id <-
          experiment_ids[[current_experiment]]
        
        # ====================================================
        # INPUT IDs
        # ====================================================
        
        variable_id <-
          paste0(
            "variable_",
            current_id
          )
        
        
        time_id <-
          paste0(
            "time_",
            current_id
          )
        
        
        plot_id <-
          paste0(
            "plot_",
            current_id
          )
        
        
        time_display_id <-
          paste0(
            "time_display_",
            current_id
          )
        
        
        play_id <-
          paste0(
            "play_",
            current_id
          )
        
        
        # ============================================================
        # DATA
        # ============================================================
        
        current_processed_data <-
          processed_data_list[[current_experiment]]
        
        
        current_sensor_data <-
          sensor_data_list[[current_experiment]]
        
        
        current_metadata <-
          metadata_list[[current_experiment]]
        
        
        current_timepoints <-
          timepoints_list[[current_experiment]]
        
        
        # ============================================================
        # PLAY / PAUSE STATE
        # ============================================================
        
        playing <-
          reactiveVal(FALSE)
        
        
        # ============================================================
        # PLAY / PAUSE BUTTON
        # ============================================================
        
        observeEvent(
          
          input[[play_id]],
          
          {
            
            playing(
              !playing()
            )
            
          }
          
        )
        
        
        # ============================================================
        # ADVANCE TIMEPOINT
        # ============================================================
        
        observe({
          
          req(
            playing()
          )
          
          invalidateLater(
            750
          )
          
          
          current_position <-
            input[[time_id]]
          
          
          if (
            
            current_position <
            length(current_timepoints)
            
          ) {
            
            updateSliderInput(
              
              session,
              
              time_id,
              
              value =
                current_position + 1
              
            )
            
          } else {
            
            playing(
              FALSE
            )
            
          }
          
        })
        
        
        # ============================================================
        # UPDATE PLAY / PAUSE BUTTON TEXT
        # ============================================================
        
        observe({
          
          if (
            playing()
          ) {
            
            updateActionButton(
              
              session,
              
              play_id,
              
              label =
                "⏸ Pause"
              
            )
            
          } else {
            
            updateActionButton(
              
              session,
              
              play_id,
              
              label =
                "▶ Play"
              
            )
            
          }
          
        })
        
        # ====================================================
        # 11.2 DISPLAY SELECTED TIME
        # ====================================================
        
        output[[time_display_id]] <-
          renderText({
            
            req(
              input[[time_id]]
            )
            
            
            selected_time <-
              current_timepoints[
                input[[time_id]]
              ]
            
            
            paste(
              
              "Timepoint:",
              
              format(
                
                selected_time,
                
                "%Y-%m-%d %H:%M"
                
              )
              
            )
            
          })
        
        
        # ====================================================
        # 11.3 RENDER ENVIRONMENTAL PLOT
        # ====================================================
        
        output[[plot_id]] <-
          renderPlotly({
            
            
            # ==================================================
            # 11.4 GET USER SELECTIONS
            # ==================================================
            
            selected_time <-
              
              current_timepoints[
                input[[time_id]]
              ]
            
            
            selected_variable <-
              input[[variable_id]]
            
            
            req(
              selected_time
            )
            
            
            req(
              selected_variable
            )
            
            
            # ==================================================
            # 11.5 FILTER ENVIRONMENTAL FIELD
            # ==================================================
            
            field_data <-
              
              current_processed_data %>%
              
              filter(
                
                Timestamp ==
                  selected_time
                
              )
            
            
            # ==================================================
            # 11.6 FILTER SENSOR DATA
            # ==================================================
            
            sensor_plot_data <-
              
              current_sensor_data %>%
              
              filter(
                
                Timestamp ==
                  selected_time
                
              )
            
            
            # ==================================================
            # 11.7 VERIFY DATA
            # ==================================================
            
            req(
              
              nrow(
                field_data
              ) > 0
              
            )
            
            
            req(
              
              nrow(
                sensor_plot_data
              ) > 0
              
            )
            
            
            # ==================================================
            # 11.8 VARIABLE LABEL
            # ==================================================
            
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
            
            
            # ============================================================
            # 11.9 ROOM DIMENSIONS FROM METADATA
            # ============================================================
            
            room_width <-
              
              as.numeric(
                
                get_metadata_value(
                  
                  current_metadata,
                  
                  "Room_Width_ft"
                  
                )
                
              )
            
            
            room_length <-
              
              as.numeric(
                
                get_metadata_value(
                  
                  current_metadata,
                  
                  "Room_Length_ft"
                  
                )
                
              )
            
            
            room_height <-
              
              as.numeric(
                
                get_metadata_value(
                  
                  current_metadata,
                  
                  "Room_Height_ft"
                  
                )
                
              )
            
            
            # ============================================================
            # 11.10 DOOR DIMENSIONS FROM METADATA
            # ============================================================
            
            door_wall <-
              
              get_metadata_value(
                
                current_metadata,
                
                "Door_Wall"
                
              )
            
            
            door_width <-
              
              as.numeric(
                
                get_metadata_value(
                  
                  current_metadata,
                  
                  "Door_Width_ft"
                  
                )
                
              )
            
            
            door_height <-
              
              as.numeric(
                
                get_metadata_value(
                  
                  current_metadata,
                  
                  "Door_Height_ft"
                  
                )
                
              )
            
            
            door_center <-
              
              as.numeric(
                
                get_metadata_value(
                  
                  current_metadata,
                  
                  "Door_Center_ft"
                  
                )
                
              )
            
            # ============================================================
            # 11.11 CREATE DOOR GEOMETRY
            # ============================================================
            
            if (
              
              door_wall %in%
              c("back", "front")
              
            ) {
              
              # ----------------------------------------------------------
              # Door is on front/back wall
              # Door center is an X coordinate
              # ----------------------------------------------------------
              
              door_x1 <-
                door_center -
                door_width / 2
              
              
              door_x2 <-
                door_center +
                door_width / 2
              
              
              door_y <-
                
                if (
                  
                  door_wall == "front"
                  
                ) {
                  
                  room_length
                  
                } else {
                  
                  0
                  
                }
              
              
              door_x <-
                c(
                  
                  door_x1,
                  door_x2,
                  NA,
                  
                  door_x1,
                  door_x1,
                  NA,
                  
                  door_x2,
                  door_x2
                  
                )
              
              
              door_y_values <-
                c(
                  
                  door_y,
                  door_y,
                  NA,
                  
                  door_y,
                  door_y,
                  NA,
                  
                  door_y,
                  door_y
                  
                )
              
              
              door_z <-
                c(
                  
                  0,
                  0,
                  NA,
                  
                  0,
                  door_height,
                  NA,
                  
                  0,
                  door_height
                  
                )
              
            }
            
            
            if (
              
              door_wall %in%
              c("left", "right")
              
            ) {
              
              # ----------------------------------------------------------
              # Door is on left/right wall
              # Door center is a Y coordinate
              # ----------------------------------------------------------
              
              door_y1 <-
                door_center -
                door_width / 2
              
              
              door_y2 <-
                door_center +
                door_width / 2
              
              
              door_x_value <-
                
                if (
                  
                  door_wall == "right"
                  
                ) {
                  
                  room_width
                  
                } else {
                  
                  0
                  
                }
              
              
              door_x <-
                c(
                  
                  door_x_value,
                  door_x_value,
                  NA,
                  
                  door_x_value,
                  door_x_value,
                  NA,
                  
                  door_x_value,
                  door_x_value
                  
                )
              
              
              door_y_values <-
                c(
                  
                  door_y1,
                  door_y2,
                  NA,
                  
                  door_y1,
                  door_y1,
                  NA,
                  
                  door_y2,
                  door_y2
                  
                )
              
              
              door_z <-
                c(
                  
                  0,
                  0,
                  NA,
                  
                  0,
                  door_height,
                  NA,
                  
                  0,
                  door_height
                  
                )
              
            }
            
            # ============================================================
            # 11.11 FIELD VALUES
            # ============================================================
            
            field_values <-
              field_data[[selected_variable]]
            
            
            # ==================================================
            # 11.12 SENSOR HOVER TEXT
            # ==================================================
            
            sensor_text <- paste(
              
              "<b>Sensor:",
              sensor_plot_data$Sensor_ID,
              "</b><br>",
              
              "Width X (ft): ",
              sensor_plot_data$X_ft,
              "<br>",
              
              "Length Y (ft): ",
              sensor_plot_data$Y_ft,
              "<br>",
              
              "Height Z (ft): ",
              sensor_plot_data$Z_ft,
              "<br>",
              
              "Temperature: ",
              
              round(
                sensor_plot_data$Temperature_F,
                2
              ),
              
              " °F<br>",
              
              "RH: ",
              
              round(
                sensor_plot_data$Relative_Humidity_pct,
                1
              ),
              
              " %<br>",
              
              "Dew Point: ",
              
              round(
                sensor_plot_data$Dew_Point_F,
                2
              ),
              
              " °F<br>",
              
              "Dew Point Depression: ",
              
              round(
                sensor_plot_data$Dew_Point_Depression_F,
                2
              ),
              
              " °F"
              
            )
            
            
            # ==================================================
            # 11.13 CREATE INTERPOLATED FIELD
            # ==================================================
            
            P <- plot_ly(
              
              data =
                field_data,
              
              x =
                ~X_ft,
              
              y =
                ~Y_ft,
              
              z =
                ~Z_ft,
              
              type =
                "scatter3d",
              
              mode =
                "markers",
              
              marker = list(
                
                size =
                  10,
                
                opacity =
                  0.15,
                
                symbol =
                  "square",
                
                color =
                  field_values,
                
                colorscale =
                  "Viridis",
                
                colorbar = list(
                  
                  title = list(
                    
                    text =
                      variable_label
                    
                  ),
                  
                  x =
                    1.12
                  
                )
                
              ),
              
              hoverinfo =
                "none",
              
              name =
                "Estimated Values"
              
            ) %>%
              
              
              # ==================================================
            # 11.14 SENSOR LOCATIONS
            # ==================================================
            
            add_trace(
              
              data =
                sensor_plot_data,
              
              x =
                ~X_ft,
              
              y =
                ~Y_ft,
              
              z =
                ~Z_ft,
              
              type =
                "scatter3d",
              
              mode =
                "markers",
              
              marker = list(
                
                size =
                  9,
                
                color =
                  "black"
                
              ),
              
              text =
                sensor_text,
              
              hoverinfo =
                "text",
              
              name =
                "Sensors",
              
              inherit =
                FALSE
              
            ) %>%
              
              
              # ============================================================
            # 11.15 ROOM DOOR
            # ============================================================
            
            add_trace(
              
              type =
                "scatter3d",
              
              mode =
                "lines",
              
              x =
                door_x,
              
              y =
                door_y_values,
              
              z =
                door_z,
              
              line = list(
                
                color =
                  "black",
                
                width =
                  8
                
              ),
              
              hoverinfo =
                "none",
              
              name =
                "Door",
              
              inherit =
                FALSE
              
            ) %>%
              
              # ==================================================
            # 11.16 FORMAT PLOT
            # ==================================================
            
            layout(
              
              scene = list(
                
                # X = WIDTH
                
                xaxis = list(
                  
                  title =
                    "Width (ft)",
                  
                  range = c(
                    
                    0,
                    room_width
                    
                  )
                  
                ),
                
                
                # Y = LENGTH
                
                yaxis = list(
                  
                  title =
                    "Length (ft)",
                  
                  range = c(
                    
                    0,
                    room_length
                    
                  )
                  
                ),
                
                
                # Z = HEIGHT
                
                zaxis = list(
                  
                  title =
                    "Height (ft)",
                  
                  range = c(
                    
                    0,
                    room_height
                    
                  )
                  
                ),
                
                aspectmode =
                  "data"
                
              ),
              
              
              legend = list(
                
                x =
                  0.01,
                
                y =
                  0.99,
                
                xanchor =
                  "left",
                
                yanchor =
                  "top"
                
              )
              
            )
            
            
            # ==================================================
            # 11.17 RETURN PLOT
            # ==================================================
            
            P
            
            
          })
        
      })
      
    }
    
  )
  
}


# ============================================================
# 12. RUN SHINY APPLICATION
# ============================================================

shinyApp(
  
  ui =
    ui,
  
  server =
    server
  
)