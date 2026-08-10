# Data Format

## Full Study Versus Committed Demo

The manuscript reports a full synthetic database of 2,170 porous-media
contamination realizations. That full dataset is not committed here because it
is large research data.

The committed example dataset is a compact subset that lets readers run the
complete RSIM workflow quickly from a fresh clone.

## Example Dataset

`examples/data/rsim_porous_media_demo.mat` contains a small subset copied from
the author-provided porous-media simulation folder.

Variables:

```text
contamination_fields
    double [300 x 120 x 80]
    Dense contamination fields. The first two dimensions are grid rows and
    columns. The third dimension indexes simulation realizations.

sensor_locations
    double [30 x 2]
    Sensor coordinates as 1-based MATLAB [row, col] indices.

sensor_values
    double [80 x 30]
    Concentration values extracted from contamination_fields at
    sensor_locations. Rows correspond to realizations; columns correspond to
    sensors.

source_files
    cell/string-like list [1 x 80]
    Original DAT filenames used to build the example subset.

metadata
    struct
    Human-readable provenance for the demo subset.
```

`examples/data/selected_sensors_30.mat` contains:

```text
selectedPixels
    uint16 [30 x 2]
    Original 30 sensor coordinates from the author-provided workspace.
```

## Raw Research Data

The original research data were found as whitespace-delimited `.dat` matrices
under folders such as:

```text
cross_section_runs/Data/Var 1/Pulse/10/
```

Each inspected `.dat` file loaded as a 300 x 120 numeric matrix.

For local reproduction with larger copied data, use:

```text
data/raw/
data/processed/
```

These folders are ignored by Git. Do not point scripts at the original
OneDrive folder when a script will write outputs; copy the data first.

## MAT File Conventions

The loader `code/io/loadContaminationField.m` looks for these variables in
MAT files, in order:

```text
X
matrixData
C
conc
concentration
data
field
```

If none exists, it falls back to the first non-empty numeric 2-D variable.
