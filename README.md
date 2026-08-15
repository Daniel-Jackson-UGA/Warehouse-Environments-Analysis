**Warehouse Environments Analysis/**
```

An R-based system for processing, interpolating, and visualizing environmental conditions within warehouse and cold-storage environments.

The project consists of an R processing workflow and an interactive Shiny application. Environmental sensor data are processed and interpolated before being provided to the Shiny application, allowing the application to remain responsive during interactive visualization.

---

**## Project Overview**

The system is designed to analyze environmental conditions within a three-dimensional warehouse environment using spatially distributed sensors.

The workflow consists of two primary components:

1. **Data processing and spatial interpolation**
2. **Interactive Shiny visualization**

The processing workflow prepares all data required by the Shiny application so that computationally intensive interpolation does not need to occur while the user is interacting with the application.

---

## Coordinate System

The warehouse is represented using a three-dimensional coordinate system.

| Axis | Represents | Direction |
|---|---|---|
| X | Width | Left → Right |
| Y | Length | Back → Front |
| Z | Height | Floor → Ceiling |

The origin is:

```text
(0, 0, 0) = Back-left-floor
````

For the current test room:

```text
Width  (X) = 25 ft
Length (Y) = 35 ft
Height (Z) = 30 ft
```

The coordinate system and room dimensions are defined within the experiment processing configuration and are not hard-coded into the Shiny application.

---

## Project Structure

```text
Warehouse Environments Analysis/
│
├── Warehouse_app/
│   └── app.R
│
├── Processing/
│   └── Process_Warehouse_Experiment_Data.R
│
├── Processed_Data/
│   ├── Experiment_processed_data.csv
│   ├── Experiment_sensor_data.csv
│   ├── Experiment_metadata.csv
│   │
│   ├── Test_Data_Set_processed_data.csv
│   ├── Test_Data_Set_sensor_data.csv
│   └── Test_Data_Set_metadata.csv
│
├── Data/
│   └── Raw experimental data
│
└── README.md
```

---

# Processing Workflow

## `Process_Warehouse_Experiment_Data.R`

The processing script is used to prepare an individual warehouse experiment for visualization.

The first section of the script contains the experiment configuration.

The configuration defines:

* Experiment name
* Input data location
* Output data location
* Room width
* Room length
* Room height
* Coordinate system
* Door location
* Door width
* Door height
* Door position
* Spatial interpolation resolution

Once the configuration is defined, the remainder of the processing script uses those values automatically.

### Example configuration

```r
experiment_name <- "Experiment"

room_width_ft  <- 25
room_length_ft <- 35
room_height_ft <- 30

door_wall <- "back"

door_width_ft  <- 7
door_height_ft <- 8

door_center_ft <- room_width_ft / 2

grid_resolution_x <- 2
grid_resolution_y <- 2
grid_resolution_z <- 2
```

The goal is for an experiment to be processed by changing the configuration at the beginning of the script rather than modifying the processing logic throughout the file.

---

# Experiment Output Files

Each processed experiment produces three CSV files.

## 1. Processed Environmental Data

```text
Experiment_processed_data.csv
```

This file contains the spatially interpolated environmental field for each timepoint.

The interpolation is performed during data processing rather than in the Shiny application.

This approach reduces the computational workload required by the interactive application and improves responsiveness.

---

## 2. Sensor Data

```text
Experiment_sensor_data.csv
```

This file contains the sensor observations and their physical locations within the warehouse.

Sensor information may include:

* Sensor ID
* Timestamp
* X coordinate
* Y coordinate
* Z coordinate
* Temperature
* Relative humidity
* Dew point
* Dew point depression

The sensor locations are displayed as black markers in the Shiny visualization.

---

## 3. Experiment Metadata

```text
Experiment_metadata.csv
```

This file contains the physical and processing configuration associated with the experiment.

Metadata include information such as:

* Experiment name
* Room width
* Room length
* Room height
* Coordinate system
* Origin
* Door wall
* Door width
* Door height
* Door position
* Grid resolution

The purpose of this file is to allow the Shiny application to understand the physical configuration of each experiment without requiring experiment-specific code.

---

# Spatial Interpolation

Environmental measurements are interpolated throughout the three-dimensional warehouse environment.

The spatial resolution is defined in the experiment configuration.

The current development configuration uses:

```text
2 ft × 2 ft × 2 ft
```

grid spacing.

Interpolation is completed before the data are loaded by the Shiny application.

This allows the Shiny application to focus primarily on visualization rather than computationally intensive spatial interpolation.

---

# Environmental Variables

The current system supports visualization of:

* Temperature
* Relative Humidity
* Dew Point
* Dew Point Depression

Additional variables can be incorporated into the processing and visualization workflow.

---

# Shiny Application

## `Warehouse_app/app.R`

The Shiny application provides an interactive three-dimensional visualization of the processed warehouse environment.

The application is designed to automatically identify experiments in the `Processed_Data` folder.

Each experiment is represented by a matching set of:

```text
*_processed_data.csv
*_sensor_data.csv
*_metadata.csv
```

The application can then create a separate tab for each experiment.

---

## Shiny Visualization

The application provides:

* Three-dimensional visualization of the warehouse
* Interpolated environmental conditions
* Actual sensor locations
* Sensor-level information
* Environmental variable selection
* Timepoint selection
* Room dimensions
* Door location for spatial orientation
* Temperature color scale
* Sensor hover information

Sensor hover information includes:

* Sensor ID
* Width/X location
* Length/Y location
* Height/Z location
* Temperature
* Relative humidity
* Dew point
* Dew point depression

---

# Adding a New Experiment

To add a new experiment:

1. Open `Process_Warehouse_Experiment_Data.R`.
2. Define the experiment configuration in the first section.
3. Specify the experiment name.
4. Specify the room dimensions.
5. Specify the door configuration.
6. Specify the interpolation resolution.
7. Run the processing script.
8. Confirm that the three CSV files are created.
9. Place the files in `Processed_Data/`.
10. Run the Shiny application.

The application is designed to automatically recognize the new experiment.

For example:

```text
Blueberry_Trial_processed_data.csv
Blueberry_Trial_sensor_data.csv
Blueberry_Trial_metadata.csv
```

will represent the experiment:

```text
Blueberry Trial
```

without requiring additional experiment-specific code in `app.R`.

---

# Data Flow

The overall workflow is:

```text
Raw Sensor Data
       │
       ▼
Process_Warehouse_Experiment_Data.R
       │
       ├───────────────┐
       │               │
       ▼               ▼
Spatial          Environmental
Interpolation       Calculations
       │               │
       └───────┬───────┘
               │
               ▼
        Processed Data
               │
       ┌───────┼────────┐
       ▼       ▼        ▼
   Processed Sensor  Metadata
      CSV      CSV      CSV
       │       │        │
       └───────┼────────┘
               ▼
          Shiny App
               │
               ▼
       Interactive 3D
       Visualization
```

---

# GitHub and Deployment

This repository is being developed for eventual deployment of the Shiny application to a hosted environment.

The intended deployment architecture is:

```text
Local R Development
        │
        ▼
      GitHub
        │
        ▼
Hosted Shiny Application
        │
        ▼
     Web Browser
        │
        ▼
      Website
```

GitHub will serve as the version-controlled source repository for the processing scripts, Shiny application, and required project files.

The Shiny application can subsequently be connected to a hosted Shiny service for public or controlled access.

---

# Development Philosophy

The project is being designed so that:

* Experiment-specific settings are defined in the processing script.
* Processing logic does not need to be rewritten for each experiment.
* Spatial interpolation is completed before deployment of the data to the Shiny application.
* The Shiny application does not perform unnecessary interpolation.
* Room dimensions are stored as experiment metadata.
* Door location and dimensions are stored as experiment metadata.
* Multiple experiments can be visualized by the same Shiny application.
* Adding an experiment does not require modifying the visualization code.

This structure is intended to make the system scalable as additional experiments and warehouse environments are added.

---

# R Packages

The project uses R packages including:

```r
readxl
dplyr
ggplot2
plotly
gstat
sp
lubridate
viridisLite
shiny
```

Additional packages may be added as the project develops.

---

# Current Development Status

**Status: Active Development**

Current capabilities include:

* Sensor data processing
* Environmental calculations
* Dew point calculation
* Dew point depression calculation
* Three-dimensional spatial interpolation
* Configurable interpolation resolution
* Three-dimensional environmental visualization
* Sensor location visualization
* Sensor hover information
* Configurable room dimensions
* Configurable door location
* Experiment-specific metadata
* Multiple experiment support
* Dynamic experiment tabs

---

# Future Development

Potential future development includes:

* Automated data ingestion
* Additional environmental variables
* Automated experiment comparison
* Environmental risk assessment
* Improved room orientation features
* Additional spatial visualization tools
* Database integration
* Cloud deployment
* Automated Shiny application updates
* User authentication and access control
* Integration with additional environmental sensors

---

# Author

Daniel Jackson

University of Georgia

---

# License

This repository is currently intended for research and development purposes.

License terms will be established prior to broader distribution or commercialization.

````

### One recommendation before you push it to GitHub

Because you're planning to eventually connect this repository to a hosted Shiny service, **I'd keep `README.md` at the root of the repository**, exactly as shown above:

```text
Warehouse Environments Analysis/
│
├── README.md          ← here
├── Warehouse_app/
├── Processing/
├── Processed_Data/
└── Data/
````

That way GitHub immediately displays the project description when someone opens the repository, and the same README will also document the project for future deployment and collaborators.
