# MATLAB Code for Abbreviated Neurocognitive Task Behavioral Analysis

## Paper Title
**Assessment of Abbreviated Neurocognitive Tasks via a Custom-Built Mobile Platform**

---

## Description

This repository contains the MATLAB scripts developed for preprocessing and behavioral data extraction in the manuscript titled "Assessment of Abbreviated Neurocognitive Tasks via a Custom-Built Mobile Platform", submitted to *Scientific Reports*.

### The scripts perform:

- Cleaning and reorganization of raw stimulus and marker data  
- Removal of empty and duplicated entries  
- Chronological alignment and sorting of events  
- Extraction of behavioral performance metrics, including:
  - Number of presented stimuli  
  - Correct responses  
  - Missed responses  
  - Incorrect responses
  
  for accuracy calculation
- Computation of reaction times  
  - `RT = response timestamp − stimulus onset timestamp`  
- Calculation of per-participant summary metrics, including: 
  - Mean RT per condition  
  - Standard deviation of RT per condition  
- Preparation of split-half datasets for reliability analysis  
- Generation of box-and-whisker visualizations  

The derived behavioral metrics were exported and used for statistical analyses conducted in:

- **Microsoft Excel** (non-parametric significance testing)  
- **IBM SPSS Statistics** (intraclass correlation coefficient, ICC)

using their built-in standard functions.

---

## Requirements

- MATLAB (tested on **R2021a**, expected to run on newer versions)
- Input data must follow the structure described below
- No additional toolboxes are required unless specified in individual scripts

---

## Input Data Structure

The input MATLAB file (e.g., `All_[TaskName]_Data.mat`) must contain a cell array where:

- Each row corresponds to one participant  
- Each column stores participant ID, stimulus stream, and response/marker stream, respectively.  

### Top-level format

`All_[TaskName]_Data.mat` → cell array of size **3 × N**

- **Column 1:** `participant_id` (numeric scalar)  

  Unique identifier of the participant  

- **Column 2:** `Stimulus` (1×1 struct)  

  Time-stamped stimulus presentation information  

- **Column 3:** `Marker` (1×1 struct)  

  Time-stamped participant responses  


### Stimulus Structure

`Stimulus` is a 1×1 struct containing:

- `time_series` (cell array, 3 × n)

  - Row 1: stimulus metadata/labels (task-specific)  
    Examples:  
    - `target/standard` (Oddball)  
    - `congruent/incongruent/neutral` (Flanker)  
    - `congruent/incongruent` (Stroop)  
    - `target/standard` (n-Back)  

  - Row 2: local timestamps in milliseconds

    Measured within the task (typically starting at 0 for each task)

  - Row 3: presentation state labels  

    Typically: `SHOW` and `HIDE`, indicating when the stimulus appears on-screen and when it is removed.

- `time_stamps` (double array, 1 × n)
  
  - Length matches `time_series` columns  


### Marker (Response) Structure

`Marker` is a 1×1 struct containing:

- `time_series` (cell array, 2 × m)

  - Row 1: participant response labels  
  - Row 2: local response times in milliseconds  

- `time_stamps` (double array, 1 × m)
  
  - Length matches `time_series` columns  

---

## Analysis Notes

- Local timestamps are task-relative and primarily used for within-task timing; universal timestamps are aligned across streams/devices (e.g., via LSL).
- Reaction times are computed using `SHOW` stimulus onset and the subsequent response marker `USER`
- Trials are classified as correct, false, or missed based on stimulus-response matching  

---

## License

This project is licensed under the **MIT License**.


## Citation

If you use this code in your research, please cite:

1. The associated research article:
   
   [Full citation here once published]

3. The code repository:
   
   DOI: https://doi.org/XXXX
