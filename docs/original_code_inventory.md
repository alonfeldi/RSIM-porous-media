# Original Code Inventory

The files below were copied from:

```text
/Users/alon_f/Library/CloudStorage/OneDrive-Technion/Thesis/yaniv/cross_section_runs
```

The original source folder was not modified.

## Active Scientific Scripts

```text
linear_iterpolation.m
```

Original end-to-end training script. It selects a data folder through a GUI,
validates MAT files containing dense fields and sensors, constructs a
fileDatastore, trains a dense fully-connected decoder with `trainNetwork`,
evaluates RMSE/correlation, and optionally visualizes basis responses and SVD.

```text
calc_entropy.m
```

Original entropy sensor-placement script. It scans MAT files, computes entropy,
selects high-entropy pixels with spacing constraints, displays the entropy map,
and writes `X`/`sensors` back into each MAT file. It can also delete invalid
files, so the refactored publication code replaces it with non-destructive
functions.

```text
compare2other_Methods.m
compare2other_Methods_log10.m
```

Original comparison scripts for classical interpolants: Linear, Natural,
Nearest, IDW, Universal Kriging, Ordinary Kriging, and RSIM. The log10 variant
contains a stray standalone `n` that appears to be a syntax bug.

## Data and Utility Scripts

```text
dat2mat.m
```

Original recursive DAT-to-MAT converter.

```text
compute_global_limits.m
```

Original scanner for global visualization limits.

```text
remove0FromDS.m
```

Filters a datastore in memory to remove all-zero samples. It does not delete
files.

```text
sort_by_VarX.m
delete_files_that_Dont_start_with_X.m
```

File-management utilities. These are preserved as legacy scripts because they
move or delete files and are not needed in the publication workflow.

```text
simulation_video.m
browseAndSavePredictions.m
pick8Montage.m
```

Visualization and figure-selection utilities from the original analysis.

## Refactored Mapping

```text
calc_entropy.m
  -> code/sensor_placement/computeEntropyMap.m
  -> code/sensor_placement/selectSensorsEntropy.m

linear_iterpolation.m
  -> scripts/run_training.m
  -> code/reconstruction/trainLinearRsimDecoder.m
  -> code/reconstruction/trainDenseNetworkDecoder.m

compare2other_Methods.m
  -> scripts/run_compare_interpolation.m
  -> code/evaluation/compareInterpolationMethods.m

dat2mat.m
  -> code/io/loadContaminationField.m
  -> code/io/loadFieldStack.m
```
