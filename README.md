# RSIM Porous Media

Research code accompanying a paper on reconstructing dense soil and
groundwater contamination fields from sparse concentration measurements using
RSIM: Ridiculously Simple Data-driven Interpolation Method.

## Overview

RSIM treats environmental interpolation as a signal reconstruction problem.
For each simulated contamination field, only a small set of sensor
measurements is provided to the reconstruction model. The model learns a
linear decoder that maps the sparse sensor vector back to the full
contamination map.

This repository focuses on heterogeneous porous-media transport. The physical
simulator generates realistic plume shapes, including preferential pathways,
stagnation regions, and sharp gradients. The RSIM reconstruction model itself
receives only sparse concentration measurements.

## Scientific Problem

Given an unknown dense contamination field `f` over a spatial domain and a
small sensor vector `z`, the goal is to learn a decoder `d` such that:

```text
z -> d(z) = f_hat
```

where `f_hat` approximates the full contamination field.

## Method

```text
porous-media simulator
        |
        v
ensemble of dense contamination fields
        |
        v
local Shannon entropy sensor placement
        |
        v
sparse concentration measurements
        |
        v
linear RSIM decoder
        |
        v
reconstructed dense field
        |
        v
RMSE / correlation / visual comparison
```

Important distinction: hydraulic conductivity is used by the physical
simulator to generate the synthetic contamination fields. It is not an input
to the RSIM reconstruction model in this repository.

## Repository Structure

```text
code/
  config/              Central experiment defaults
  io/                  Data loading utilities
  preprocessing/       Sensor measurement extraction and data splits
  sensor_placement/    Entropy-map and sensor-selection code
  reconstruction/      Linear RSIM decoder and original dense-network wrapper
  evaluation/          Metrics and interpolation comparisons
  visualization/       Plotting helpers

scripts/
  run_demo.m
  run_training.m
  run_evaluation.m
  run_compare_interpolation.m
  run_sensitivity_analysis.m

examples/data/
  rsim_porous_media_demo.mat
  selected_sensors_30.mat

docs/
  methodology.md
  data_format.md
  original_code_inventory.md

legacy/original_matlab/
  Original MATLAB scripts copied from the author-provided folder

results/figures/
  Small copied summary artifacts from the existing research run
```

## Requirements

The lightweight demo uses base MATLAB functionality such as `histcounts`,
`scatteredInterpolant`, `table`, `writetable`, `tiledlayout`, and
`exportgraphics`. A MATLAB release that supports `tiledlayout` and
`exportgraphics` is recommended.

Additional optional dependencies from the original scripts:

- Deep Learning Toolbox: original dense fully-connected training workflow
  using `trainNetwork`, `imageInputLayer`, `fullyConnectedLayer`, and
  `depthToSpace2dLayer`.
- Image Processing Toolbox: original montage utilities using `montage`.
- Python with PyKrige: optional Universal/Ordinary Kriging comparisons through
  MATLAB `pyrun`.

## Quick Start

Open MATLAB in the repository root and run:

```matlab
run("scripts/run_demo.m")
```

The demo writes outputs under `results/demo/`, including metrics, a trained
demo decoder, an entropy/sensor map, and a reconstruction comparison figure.

For a non-visual smoke test:

```matlab
run("tests/test_core_functions.m")
```

## Data

The committed example dataset is intentionally small:

- `examples/data/rsim_porous_media_demo.mat` contains 80 dense fields of size
  300 x 120.
- `examples/data/selected_sensors_30.mat` contains the 30 sensor locations from
  the original workspace.

Large raw/processed research datasets should be copied into `data/raw/` or
`data/processed/` locally. These folders are ignored by Git to avoid publishing
large generated files by accident.

See [docs/data_format.md](docs/data_format.md) for variable names and
dimensions.

## Reproducing Experiments

- `scripts/run_demo.m`: fast end-to-end RSIM reconstruction on example data.
- `scripts/run_training.m`: train the linear RSIM decoder on copied research
  data under `data/processed/`.
- `scripts/run_evaluation.m`: evaluate the demo workflow and write metrics.
- `scripts/run_compare_interpolation.m`: compare RSIM with Linear, Natural,
  Nearest, and IDW interpolation on a held-out demo field.
- `scripts/run_sensitivity_analysis.m`: demo-scale sensitivity to number of
  sensors.

The original exploratory MATLAB scripts are preserved in
`legacy/original_matlab/` for traceability. See
[docs/original_code_inventory.md](docs/original_code_inventory.md).

## Citation

If you use this repository, please cite the accompanying paper once the final
bibliographic information is available. A software citation placeholder is
provided in [CITATION.cff](CITATION.cff).
