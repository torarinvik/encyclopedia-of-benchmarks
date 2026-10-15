proc maximum_sum_of_distinct_subarrays_with_length_k*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "maximum_sum_of_distinct_subarrays_with_length_k".} =
  const invalid = low(int64)
  const maxN = 8192
  const capacity = 16384
  if values.isNil or length < 3 or length > capacity div 2 + 2: return invalid
  let nValue = values[0]
  let kValue = values[1]
  if nValue < 1 or nValue > maxN or kValue < 1 or kValue > nValue: return invalid
  let n = int(nValue)
  let k = int(kValue)
  if length != csize_t(n + 2): return invalid
  var keys: array[capacity, int32]
  var lastPlusOne: array[capacity, int32]
  var currentSum = 0'i64
  var maximumSum = 0'i64
  var distinctStart = 0
  for i in 0 ..< n:
    let input = values[i + 2]
    if input < low(int32).int64 or input > high(int32).int64: return invalid
    let value = int32(input)
    if i < k: currentSum += value
    else:
      currentSum -= values[i - k + 2]
      currentSum += value
    var slot = int((input + 2147483648'i64) mod 16384'i64)
    while lastPlusOne[slot] != 0 and keys[slot] != value: slot = (slot + 1) and (capacity - 1)
    if lastPlusOne[slot] != 0:
      let previous = int(lastPlusOne[slot] - 1)
      if previous >= distinctStart: distinctStart = previous + 1
    else: keys[slot] = value
    lastPlusOne[slot] = int32(i + 1)
    if i + 1 >= k:
      let start = i + 1 - k
      if start >= distinctStart and currentSum > maximumSum: maximumSum = currentSum
  maximumSum
