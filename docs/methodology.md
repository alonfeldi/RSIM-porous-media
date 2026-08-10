# Methodology Notes

## Scientific Pipeline

The repository is organized around five separate stages:

1. Physical data generation: external porous-media simulations produce dense
   contamination fields.
2. Sensor placement: local Shannon entropy is computed over an ensemble of
   dense fields. High-entropy cells are selected while enforcing row/column
   spacing.
3. Sparse measurement extraction: the dense fields are sampled at the selected
   sensor locations, with optional multiplicative Gaussian noise.
4. RSIM reconstruction: a linear decoder maps sparse sensor vectors to dense
   contamination fields.
5. Evaluation and visualization: reconstructions are compared with ground
   truth using RMSE, relative RMSE, mean-centered correlation, and figures.

Hydraulic conductivity belongs to stage 1 only. It is not passed into the RSIM
decoder.

## Sensor Placement

The original `calc_entropy.m` script computes one entropy value per grid cell
from the ensemble distribution at that cell. The refactored implementation is:

- `code/sensor_placement/computeEntropyMap.m`
- `code/sensor_placement/selectSensorsEntropy.m`

The spacing rule intentionally preserves the original behavior. A candidate is
rejected when it is closer than both the vertical and horizontal thresholds to
an already selected sensor. A difference equal to the threshold is accepted,
because the original code used the strict `<` operator.

## Reconstruction Model

The publication-facing core implementation uses:

- `code/reconstruction/trainLinearRsimDecoder.m`
- `code/reconstruction/predictLinearRsimDecoder.m`

The model maps a sensor vector to the flattened contamination field:

```text
f_hat(:)' = z * W + b
```

The current default configuration sets `cfg.useBias = false` to match the
original dense-network MATLAB script, which initialized the fully-connected
bias to zero and set `BiasLearnRateFactor` to zero. If the final paper method
requires an intercept term, set `cfg.useBias = true`.

The original dense-network architecture is also available in
`code/reconstruction/trainDenseNetworkDecoder.m`. It preserves the original
single fully-connected layer workflow and requires the MATLAB Deep Learning
Toolbox.

## Evaluation

The original scripts report mean RMSE and mean-centered matrix correlation.
The refactored code exposes both per-sample metrics and summary metrics through
`code/evaluation/evaluateReconstruction.m`.

Classical interpolation comparison is implemented in:

- `code/evaluation/compareInterpolationMethods.m`

The demo comparison includes Linear, Natural, Nearest, IDW, and RSIM. The
legacy scripts retain the optional PyKrige Universal/Ordinary Kriging calls.

## Ambiguities Preserved or Flagged

- Bias term: the paper description uses `Wz + b`, while the original network
  code freezes the bias at zero. The default preserves the original behavior.
- Sensor placement split: the original workflow appears to compute sensors
  before train/validation/test splitting. The demo follows that behavior.
- Log-scale visualization: the legacy log comparison uses thresholded
  `log10(x)`, which maps zeros to `-Inf`. This is preserved in legacy code and
  not used in the base demo.
- `compare2other_Methods_log10.m` contains a stray standalone `n`, which is a
  clear syntax issue in the original file. The legacy copy is unchanged; the
  refactored comparison code does not include that typo.

## Non-Destructive Refactor

The original `calc_entropy.m` script deletes invalid files and writes `X` and
`sensors` variables back into each MAT file. Publication code should avoid
surprising writes to research data, so the refactored functions compute and
return values without modifying input files.
