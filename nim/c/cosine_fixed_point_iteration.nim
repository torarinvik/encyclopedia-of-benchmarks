import std/math

proc cosine_fixed_point_iteration*(initialInput, sourceN: float64): float64
    {.cdecl, exportc: "cosine_fixed_point_iteration".} =
  if initialInput != initialInput or sourceN != sourceN or
      initialInput < 0.0 or initialInput > 2.0 or sourceN < 0.0 or sourceN > 64.0 or
      floor(sourceN) != sourceN:
    return -1.0

  var value = initialInput
  let updates = int(sourceN) + 1
  for iteration in 0 ..< updates:
    value = 0.5 * (cos(value) + 2.0)
  value
