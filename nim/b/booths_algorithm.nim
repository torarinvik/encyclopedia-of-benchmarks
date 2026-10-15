proc booths_algorithm*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "booths_algorithm".} =
  if values.isNil or length == 0 or length > 256: return -1
  for index in 0 ..< int(length):
    if values[index] < 0 or values[index] > 127: return -1
  if output.isNil or int(capacity) < int(length): return -2

  var failure: array[512, int64]
  for index in 0 ..< 2 * int(length): failure[index] = -1
  var start = 0
  for j in 1 ..< 2 * int(length):
    let current = values[j mod int(length)]
    var matched = failure[j - start - 1]
    while matched != -1 and current != values[(start + int(matched) + 1) mod int(length)]:
      if current < values[(start + int(matched) + 1) mod int(length)]:
        start = j - int(matched) - 1
      matched = failure[int(matched)]
    if matched == -1 and current != values[start mod int(length)]:
      if current < values[start mod int(length)]: start = j
      failure[j - start] = -1
    else:
      failure[j - start] = matched + 1

  for index in 0 ..< int(length):
    output[index] = uint8(values[(start + index) mod int(length)])
  int64(length)
