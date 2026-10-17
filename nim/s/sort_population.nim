proc writeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0..<8:
    output[offset + byte] = uint8(bits shr (byte * 8))

proc sort_population*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "sort_population".} =
  if input.isNil or length < 3 or length > 129: return -1
  if input[0] < 1 or input[0] > 64: return -1
  let count = int(input[0])
  if int(length) != 1 + 2 * count: return -1
  var costs: array[64, int64]
  var identifiers: array[64, int64]
  var seen: array[64, bool]
  for index in 0..<64: seen[index] = false
  for index in 0..<count:
    let cost = input[1 + 2 * index]
    let identifier = input[2 + 2 * index]
    if cost < -1000000 or cost > 1000000 or identifier < 0 or identifier >= int64(count): return -1
    if seen[int(identifier)]: return -1
    seen[int(identifier)] = true
    costs[index] = cost
    identifiers[index] = identifier
  for index in 1..<count:
    let keyCost = costs[index]
    let keyIdentifier = identifiers[index]
    var position = index
    while position > 0 and costs[position - 1] > keyCost:
      costs[position] = costs[position - 1]
      identifiers[position] = identifiers[position - 1]
      dec position
    costs[position] = keyCost
    identifiers[position] = keyIdentifier
  for index in 1..<count:
    if costs[index - 1] == costs[index]: return -1
  let outputLength = count * 16
  if output.isNil or capacity < csize_t(outputLength): return -2
  for index in 0..<count:
    writeI64Le(output, index * 16, costs[index])
    writeI64Le(output, index * 16 + 8, identifiers[index])
  int64(outputLength)
