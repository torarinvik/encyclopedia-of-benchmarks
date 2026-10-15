## Return P(A | B) from P(A), P(B), and P(B | A).
proc bayes_theorem*(probabilityA, probabilityB, probabilityBGivenA: float64): float64
    {.cdecl, exportc: "bayes_theorem".} =
  if probabilityA < 0.0 or probabilityA > 1.0 or
      probabilityB <= 0.0 or probabilityB > 1.0 or
      probabilityBGivenA < 0.0 or probabilityBGivenA > 1.0:
    return -1.0
  let jointProbability = probabilityA * probabilityBGivenA
  if jointProbability > probabilityB: return -1.0
  jointProbability / probabilityB
