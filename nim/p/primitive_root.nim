## Search in ascending order for a full period of distinct residues.
proc primitive_root*(input: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "primitive_root".} =
  if input == nil or length != 1 or input[0] < 2 or input[0] > 127: return -1
  let modulus = int(input[0])
  for candidate in 1 ..< modulus:
    var seen: array[127, bool]
    var power = 1
    var isDistinct = true
    for exponent in 0 ..< modulus - 1:
      if seen[power]:
        isDistinct = false
        break
      seen[power] = true
      power = (power * candidate) mod modulus
    if isDistinct: return int64(candidate)
  return 0
