proc shannon_fano_elias_symbol_codes*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "shannon_fano_elias_symbol_codes".} =
  if input == nil or length < 2 or length > 10: return -1
  let rawN = input[0]
  if rawN < 1 or rawN > 8 or int(length) != int(rawN) + 1: return -1
  let n = int(rawN)
  var total = 0'i64
  for i in 0 ..< n:
    let weight = input[1+i]
    if weight < 1 or weight > 15: return -1
    total += weight
  if total > 120: return -1

  var staged: array[17, uint8]
  staged[0] = uint8(n)
  var prefix = 0'i64
  for i in 0 ..< n:
    let weight = input[1+i]
    var bits = 1
    while (1'i64 shl (bits-1)) * weight < total: inc bits
    let numerator = (2*prefix + weight) * (1'i64 shl (bits-1))
    let code = uint8(numerator div total)
    staged[1+2*i] = uint8(bits)
    staged[2+2*i] = code shl (8-bits)
    prefix += weight
  let needed = 1 + 2*n
  if output == nil or capacity < csize_t(needed): return -2
  for i in 0 ..< needed: output[i] = staged[i]
  int64(needed)
