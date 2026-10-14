## Stable LSD radix sort for signed 64-bit values.
proc radixOrderKey(value: int64): uint64 =
  let signBit = 1'u64 shl 63
  if value < 0:
    return signBit - 1'u64 - uint64(-(value + 1))
  signBit + uint64(value)

proc radix_sort*(values, scratch: ptr UncheckedArray[int64], length: csize_t) {.cdecl, exportc: "radix_sort".} =
  if length < 2:
    return
  for pass in 0 .. 7:
    for bucket in 0 .. 255:
      scratch[bucket] = 0
    let shift = pass * 8
    for index in 0 ..< length:
      let bucket = int((radixOrderKey(values[index]) shr shift) and 255'u64)
      inc scratch[bucket]
    var next = csize_t(0)
    for bucket in 0 .. 255:
      let count = csize_t(scratch[bucket])
      scratch[bucket] = int64(next)
      next += count
    for index in 0 ..< length:
      let bucket = int((radixOrderKey(values[index]) shr shift) and 255'u64)
      let destination = csize_t(scratch[bucket])
      inc scratch[bucket]
      scratch[256 + destination] = values[index]
    for index in 0 ..< length:
      values[index] = scratch[256 + index]
