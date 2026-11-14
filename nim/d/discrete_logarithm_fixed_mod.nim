proc discrete_logarithm_fixed_mod*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc.} =
  if input == nil or length < 3 or length > 259: return -1
  if input[0] < 2 or input[0] > 4093 or input[1] < 1 or input[1] >= input[0] or
      input[2] < 1 or input[2] > 256: return -1
  let p = int(input[0])
  let g = int(input[1])
  let n = int(input[2])
  if length != csize_t(n + 3): return -1
  var divisor = 2
  while divisor * divisor <= p:
    if p mod divisor == 0: return -1
    inc divisor
  for i in 0 ..< n:
    if input[3+i] < 1 or input[3+i] >= int64(p): return -1
  var table: array[4094, int16]
  for i in 0 ..< p: table[i] = -1
  var residue = 1
  for exponent in 0 ..< p-1:
    if table[residue] != -1: return -1
    table[residue] = int16(exponent)
    residue = residue * g mod p
  if residue != 1: return -1
  if output == nil or capacity < csize_t(8*n): return -2
  for i in 0 ..< n:
    let value = uint64(table[int(input[3+i])])
    for byte in 0 ..< 8:
      output[8*i+byte] = uint8((value shr (8*byte)) and 255'u64)
  int64(8*n)
