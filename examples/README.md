# Examples

Run the demo from the repository root:

```matlab
run("scripts/run_demo.m")
```

The demo uses `examples/data/rsim_porous_media_demo.mat`, a compact subset of
80 porous-media contamination fields. It computes an entropy map, loads the
stored 30 research sensor locations, trains a linear RSIM decoder, reconstructs
held-out fields, and saves outputs under `results/demo/`.

See `docs/data_format.md` for the exact variables and dimensions.
