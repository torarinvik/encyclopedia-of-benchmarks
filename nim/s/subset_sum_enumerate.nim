## Emit the index masks of all signed subsets matching the target.
proc subset_sum_enumerate*(input: ptr UncheckedArray[int64], length: csize_t,
                           output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "subset_sum_enumerate".} =
  if length == 0 or length > 9: return -1
  let target = input[0]
  if target < -512 or target > 512: return -1
  let items = length - 1
  for index in 0 ..< items:
    if input[index + 1] < -64 or input[index + 1] > 64: return -1

  var masks: array[256, uint8]
  var count = 0
  let limit = 1 shl int(items)
  for mask in 0 ..< limit:
    var sum = 0'i64
    for index in 0 ..< int(items):
      if (mask div (1 shl index)) mod 2 == 1:
        sum += input[csize_t(index) + 1]
    if sum == target:
      masks[count] = uint8(mask)
      inc count
  if outputCapacity < csize_t(count): return -2
  for index in 0 ..< count: output[csize_t(index)] = masks[index]
  int64(count)
