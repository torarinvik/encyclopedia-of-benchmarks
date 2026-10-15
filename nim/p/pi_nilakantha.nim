proc pi_nilakantha*(input: float64): float64 {.cdecl, exportc: "pi_nilakantha".} =
  if not (input >= 0.0 and input <= 500.0 and input == float64(int32(input))): return -1.0
  let iterations = int32(input)
  var pi = 3.0
  var divCounter = 2'i32
  for i in 0'i32 ..< iterations:
    let term = 4.0 / float64(divCounter * (divCounter + 1) * (divCounter + 2))
    if i mod 2 == 0: pi = pi + term
    else: pi = pi - term
    divCounter += 2
  return pi
