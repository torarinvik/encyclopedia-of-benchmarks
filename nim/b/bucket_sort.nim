## Stable top-byte bucket sort for signed 64-bit values.
proc bucketOrderKey(value: int64): uint64 =
  let signBit = 1'u64 shl 63
  if value < 0:
    return signBit - 1'u64 - uint64(-(value + 1))
  signBit + uint64(value)

proc bucketSortInsertion(values: ptr UncheckedArray[int64], base, low, high: csize_t) =
  var index = low
  if low < high:
    inc index
  while index < high:
    let key = values[base + index]
    var position = index
    while position > low and values[base + position - 1] > key:
      values[base + position] = values[base + position - 1]
      dec position
    values[base + position] = key
    inc index

proc bucket_sort*(values, scratch: ptr UncheckedArray[int64], length: csize_t) {.cdecl, exportc: "bucket_sort".} =
  if length < 2:
    return
  for bucket in 0 .. 255:
    scratch[bucket] = 0
  for index in 0 ..< length:
    let bucket = int(bucketOrderKey(values[index]) shr 56)
    inc scratch[bucket]
  var next = csize_t(0)
  for bucket in 0 .. 255:
    let count = csize_t(scratch[bucket])
    scratch[bucket] = int64(next)
    next += count
  for index in 0 ..< length:
    let bucket = int(bucketOrderKey(values[index]) shr 56)
    let destination = csize_t(scratch[bucket])
    inc scratch[bucket]
    scratch[256 + destination] = values[index]
  var low = csize_t(0)
  for bucket in 0 .. 255:
    let high = csize_t(scratch[bucket])
    bucketSortInsertion(scratch, 256, low, high)
    low = high
  for index in 0 ..< length:
    values[index] = scratch[256 + index]
