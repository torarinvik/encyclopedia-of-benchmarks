## Sum a finite geometric progression using the pinned closed form.
import std/math

proc sum_of_geometric_progression*(firstTerm, commonRatio, numTerms: float64): float64
    {.cdecl, exportc: "sum_of_geometric_progression".} =
  if commonRatio == 1.0: return numTerms * firstTerm
  (firstTerm / (1.0 - commonRatio)) * (1.0 - pow(commonRatio, numTerms))
