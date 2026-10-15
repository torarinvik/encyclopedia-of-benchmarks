## Apply an affine conversion in the source operation order: slope * x + intercept.
proc affine_converter*(slope, x, intercept: float64): float64
    {.cdecl, exportc: "affine_converter".} =
  slope * x + intercept
