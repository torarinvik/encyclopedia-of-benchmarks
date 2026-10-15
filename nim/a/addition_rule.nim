## Probability of A or B using the conditional probability P(B | A).
proc addition_rule*(probabilityA, probabilityB, probabilityBGivenA: float64): float64
    {.cdecl, exportc: "addition_rule".} =
  (probabilityA + probabilityB) - (probabilityA * probabilityBGivenA)
