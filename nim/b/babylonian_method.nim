proc babylonian_method*(input: float64): float64 {.cdecl, exportc: "babylonian_method".} =
  if not (input >= 2.0 and input <= 999_999.0): return -1.0
  let radicand = int64(input)
  if float64(radicand) != input: return -1.0
  var i: int64 = 1
  while i * i <= radicand: inc i
  dec i
  if i * i == radicand: return -1.0
  let x0 = float64(i)
  (input / x0 + x0) / 2.0
