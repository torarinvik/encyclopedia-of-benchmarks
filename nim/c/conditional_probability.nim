## Return P(A | B) from P(A intersection B) and P(B).
proc conditional_probability*(probabilityIntersection, probabilityB: float64): float64
    {.cdecl, exportc: "conditional_probability".} =
  if probabilityIntersection != probabilityIntersection or probabilityB != probabilityB or
      probabilityB <= 0.0 or probabilityB > 1.0 or
      probabilityIntersection < 0.0 or probabilityIntersection > probabilityB:
    return -1.0
  probabilityIntersection / probabilityB
