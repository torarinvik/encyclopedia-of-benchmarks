const MaxN = 3
const MaxOutputBytes = 144

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc johnson_trotter_adjacent_gray_code*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "johnson_trotter_adjacent_gray_code".} =
  if input.isNil or length != csize_t(1) or input[0] < 1 or input[0] > int64(MaxN): return -1
  let n = int(input[0])
  var permutationCount = 1
  if n > 1:
    for value in 2 .. n: permutationCount *= value
  let outputBytes = 8 * n * permutationCount
  if output.isNil or int(capacity) < outputBytes: return -2
  var permutation: array[MaxN, int64]
  var direction: array[MaxN + 1, int64]
  for index in 0 ..< n:
    permutation[index] = int64(index + 1)
    direction[index + 1] = -1
  var staged: array[MaxOutputBytes, uint8]
  var rows = 0
  while true:
    for index in 0 ..< n: storeI64Le(addr staged[0], 8 * (rows * n + index), permutation[index])
    inc rows
    var largestMobile = 0'i64
    var mobilePosition = -1
    for position in 0 ..< n:
      let value = permutation[position]
      let neighbor = position + int(direction[int(value)])
      if neighbor >= 0 and neighbor < n and value > permutation[neighbor] and value > largestMobile:
        largestMobile = value
        mobilePosition = position
    if mobilePosition < 0: break
    let neighbor = mobilePosition + int(direction[int(largestMobile)])
    swap(permutation[mobilePosition], permutation[neighbor])
    for value in int(largestMobile) + 1 .. n: direction[value] = -direction[value]
  for byte in 0 ..< outputBytes: output[byte] = staged[byte]
  int64(outputBytes)
