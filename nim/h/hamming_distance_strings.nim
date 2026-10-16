proc hamming_distance_strings*(input: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "hamming_distance_strings".} =
  if input == nil or length < 2 or length > 260: return -1
  let leftLength = input[0]
  let rightLength = input[1]
  if leftLength < 0 or leftLength > 128 or rightLength < 0 or rightLength > 128: return -1
  if length != csize_t(2 + leftLength + rightLength): return -1
  for i in 2 ..< int(length):
    if input[i] < 0 or input[i] > 255: return -1
  if leftLength != rightLength: return -1
  var distance = 0'i64
  for i in 0 ..< int(leftLength):
    if input[2 + i] != input[2 + int(leftLength) + i]: inc distance
  return distance
