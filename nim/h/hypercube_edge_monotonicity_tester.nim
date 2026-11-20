proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (byte * 8)) and 255)

proc hypercube_edge_monotonicity_tester*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "hypercube_edge_monotonicity_tester".} =
  if input.isNil or length < 2 or length > 130: return -1
  let nValue = input[0]
  let qValue = input[1]
  if nValue < 1 or nValue > 6 or qValue < 1 or qValue > 32: return -1
  let n = int(nValue)
  let q = int(qValue)
  let domain = 1 shl n
  if int(length) != 2 + domain + 2 * q: return -1
  for vertex in 0 ..< domain:
    if input[2 + vertex] != 0 and input[2 + vertex] != 1: return -1
  let tape = 2 + domain
  for round in 0 ..< q:
    let vertex = input[tape + 2 * round]
    let coordinate = input[tape + 2 * round + 1]
    if vertex < 0 or vertex >= int64(domain) or coordinate < 0 or coordinate >= nValue: return -1
  var accepted = 1'i64
  var rounds = 0'i64
  for round in 0 ..< q:
    let vertex = int(input[tape + 2 * round])
    let bit = 1 shl int(input[tape + 2 * round + 1])
    let lower = vertex and not bit
    inc rounds
    if input[2 + lower] > input[2 + (lower or bit)]:
      accepted = 0
      break
  if output.isNil or capacity < 24: return -2
  storeI64Le(output, 0, accepted)
  storeI64Le(output, 8, rounds)
  storeI64Le(output, 16, 2 * rounds)
  24
