## The source module exposes three mirror-equation rearrangements.
proc valid_distance(value: float64): bool =
  (value >= -1.0e6 and value <= -1.0e-6) or (value >= 1.0e-6 and value <= 1.0e6)

proc mirror_formulae*(distance_a, distance_b, operation_code: float64): float64 {.cdecl, exportc: "mirror_formulae".} =
  let invalid = -1.0e300
  if not valid_distance(distance_a) or not valid_distance(distance_b):
    return invalid
  if operation_code != 0.0 and operation_code != 1.0 and operation_code != 2.0:
    return invalid

  var denominator: float64
  if operation_code == 0.0:
    denominator = (1.0 / distance_a) + (1.0 / distance_b)
  else:
    denominator = (1.0 / distance_a) - (1.0 / distance_b)
  if denominator == 0.0:
    return invalid
  1.0 / denominator
