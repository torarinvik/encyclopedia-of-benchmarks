proc directed_perfect_phylogeny*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "directed_perfect_phylogeny".} =
  if input.isNil or length < 3 or length > 146: return -1
  let n0 = input[0]; let m0 = input[1]
  if n0 < 1 or n0 > 12 or m0 < 1 or m0 > 12 or int(length) != 2 + int(n0 * m0): return -1
  let n = int(n0); let m = int(m0)
  var sets: array[12, uint16]
  for row in 0..<n:
    for col in 0..<m:
      let bit = input[2 + row * m + col]
      if bit != 0 and bit != 1: return -1
      if bit == 1: sets[col] = sets[col] or (uint16(1) shl row)
  var feasible = true
  for a in 0..<m:
    for b in a+1..<m:
      let overlap = sets[a] and sets[b]
      if overlap != 0 and overlap != sets[a] and overlap != sets[b]: feasible = false
  if output.isNil or capacity < 8: return -2
  let result = if feasible: 1'i64 else: 0'i64
  let bits = cast[uint64](result)
  for b in 0..<8: output[b] = uint8((bits shr (8*b)) and 255)
  8
