const MaxSequenceLength = 256

proc lyndon_factorization*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "lyndon_factorization".} =
  if length < 1 or length > csize_t(MaxSequenceLength + 1) or input == nil: return -1
  if input[0] < 0 or input[0] > MaxSequenceLength or length != csize_t(input[0]) + 1: return -1
  let n = int(input[0])
  for i in 0 ..< n:
    if input[i + 1] < 97 or input[i + 1] > 122: return -1
  let required = 2 * n
  if capacity < csize_t(required) or (required != 0 and output == nil): return -2
  var start = 0
  var out = 0
  while start < n:
    var candidate = start + 1
    var matched = start
    while candidate < n and input[matched + 1] <= input[candidate + 1]:
      if input[matched + 1] < input[candidate + 1]: matched = start
      else: inc matched
      inc candidate
    let factorLength = candidate - matched
    while start <= matched:
      for j in 0 ..< factorLength:
        output[out] = uint8(input[start + j + 1]); inc out
      output[out] = 0; inc out
      start += factorLength
  int64(out)
