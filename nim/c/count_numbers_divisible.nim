## Count multiples of divisor in the inclusive positive integer interval [first, last].
proc count_numbers_divisible*(first, last, divisor: float64): float64
    {.cdecl, exportc: "count_numbers_divisible".} =
  let a = int64(first)
  let b = int64(last)
  let m = int64(divisor)
  float64(b div m - (a - 1) div m)
