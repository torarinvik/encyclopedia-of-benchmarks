import std/math

## Probability of exactly x successes in n Bernoulli trials.
proc binomial_dist*(n, p, x: float64): float64 {.cdecl, exportc: "binomial_dist".} =
  let nInteger = int(n)
  let xInteger = int(x)
  var numerator = n
  var denominator = x
  var i = nInteger - 1
  while i >= nInteger - xInteger + 1:
    numerator *= float64(i)
    dec i
  i = 1
  while i < xInteger:
    denominator *= float64(i)
    inc i
  (numerator / denominator) * pow(p, x) * pow(1.0 - p, n - x)
