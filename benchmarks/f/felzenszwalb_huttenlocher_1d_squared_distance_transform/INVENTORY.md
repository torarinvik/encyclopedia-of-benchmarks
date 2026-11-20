# Static package inventory

The package exports `felzenszwalb_huttenlocher_1d_squared_distance_transform`
with the `i64_array_bytes_output` ABI in ten language paths pinned by
`INVENTORY.json`. It uses a fixed-size integer lower envelope and emits an
interleaved distance/site pair for each coordinate. Input is bounded to 128
sites, costs to 0 through 1,000,000, output to 2,048 bytes, and package
workspace to 4,096 bytes.

The workload pins 12 valid, invalid, and ABI-error fixtures. The primary
reference uses exact envelope breakpoints; the independent reference performs
direct all-sites minimization with index tie-breaking. The package also
contains its source and rights note, workload verifier, and static inventory
checker. These validation artifacts have not been run.
