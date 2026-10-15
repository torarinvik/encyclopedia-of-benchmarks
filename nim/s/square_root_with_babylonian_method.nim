proc square_root_with_babylonian_method*(input: float64): float64 {.cdecl, exportc: "square_root_with_babylonian_method".} =
  if not (input >= 1.0 and input <= 1000000.0): return -1.0
  let num = float32(input)
  var a = num
  var b = 1.0'f32
  let epsilon = 0.000001
  while float64(a - b) > epsilon:
    a = (a + b) / 2.0'f32
    b = num / a
  return float64(a)
