proc msdOrderKey(value: int64): uint64 =
  let signBit = 1'u64 shl 63
  if value < 0:
    return signBit - 1'u64 - uint64(-(value + 1))
  signBit + uint64(value)

proc msdSortRange(values: ptr UncheckedArray[int64], beginIndex, endIndex: csize_t, bitPosition: int) =
  if endIndex - beginIndex < 2 or bitPosition < 0:
    return
  var left = beginIndex
  var right = endIndex
  while left < right:
    while left < right and ((msdOrderKey(values[left]) shr bitPosition) and 1'u64) == 0'u64:
      inc left
    while left < right and ((msdOrderKey(values[right - 1]) shr bitPosition) and 1'u64) != 0'u64:
      dec right
    if left < right:
      swap(values[left], values[right - 1])
      inc left
      dec right
  msdSortRange(values, beginIndex, left, bitPosition - 1)
  msdSortRange(values, left, endIndex, bitPosition - 1)

proc msd_radix_sort*(values: ptr UncheckedArray[int64], length: csize_t) {.cdecl, exportc: "msd_radix_sort".} =
  if length > 1:
    msdSortRange(values, 0, length, 63)
