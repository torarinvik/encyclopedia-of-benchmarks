## Binary64 interpolation in the classic start + t * (end - start) form.
proc lerp*(start, ending, t: float64): float64 {.cdecl, exportc: "lerp".} =
  start + t * (ending - start)
