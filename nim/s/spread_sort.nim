const
  MaxLength = 128
  InsertionThreshold = 16
  MaxBuckets = 8
  BucketStride = 128

proc spreadSortSegment(values: var array[1024, int32], start, length: int) =
  if length < 2: return
  if length <= InsertionThreshold:
    for index in 1 ..< length:
      let key = values[start + index]
      var position = index
      while position > 0 and values[start + position - 1] > key:
        values[start + position] = values[start + position - 1]
        dec position
      values[start + position] = key
    return

  var minimum = values[start]
  var maximum = values[start]
  for index in 1 ..< length:
    if values[start + index] < minimum: minimum = values[start + index]
    if values[start + index] > maximum: maximum = values[start + index]
  if minimum == maximum: return

  var bucketCount = length div InsertionThreshold
  if bucketCount < 2: bucketCount = 2
  let middleBucket = bucketCount div 2
  var bucketValues: array[1024, int32]
  var bucketSizes: array[MaxBuckets, int]
  for index in 0 ..< MaxBuckets: bucketSizes[index] = 0
  for index in 0 ..< length:
    let bucket = if values[start + index] == minimum: 0 else: middleBucket
    let position = bucket * BucketStride + bucketSizes[bucket]
    bucketValues[position] = values[start + index]
    inc bucketSizes[bucket]

  var written = 0
  for bucket in 0 ..< bucketCount:
    if bucketSizes[bucket] > 0:
      spreadSortSegment(bucketValues, bucket * BucketStride, bucketSizes[bucket])
      for index in 0 ..< bucketSizes[bucket]:
        values[start + written] = bucketValues[bucket * BucketStride + index]
        inc written

proc spread_sort*(input: ptr UncheckedArray[int64], length: csize_t,
                  output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "spread_sort".} =
  if input == nil or length > csize_t(MaxLength): return -1
  var values: array[1024, int32]
  for index in 0 ..< int(length):
    let value = input[index]
    if value < int64(low(int32)) or value > int64(high(int32)): return -1
    values[index] = int32(value)
  if length == 0: return 0

  let outputBytes = length * 4
  if output == nil or capacity < outputBytes: return -2
  spreadSortSegment(values, 0, int(length))
  for index in 0 ..< int(length):
    let bits = cast[uint32](values[index])
    output[index * 4] = uint8(bits and 255)
    output[index * 4 + 1] = uint8((bits shr 8) and 255)
    output[index * 4 + 2] = uint8((bits shr 16) and 255)
    output[index * 4 + 3] = uint8((bits shr 24) and 255)
  int64(outputBytes)
