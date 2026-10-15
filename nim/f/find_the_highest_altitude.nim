proc find_the_highest_altitude*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "find_the_highest_altitude".} =
  if input.isNil or length < 1 or input[0] < 0 or input[0] > 1024 or length != csize_t(input[0] + 1): return -1
  let n = int(input[0])
  var altitude = 0'i64
  var maximum = 0'i64
  for i in 0 ..< n:
    let gain = input[i + 1]
    if gain < int64(low(int32)) or gain > int64(high(int32)): return -1
    altitude += gain
    if altitude > maximum: maximum = altitude
  maximum
