## Check whether the values are a rotation of a nondecreasing array.
proc check_if_array_is_sorted_and_rotated*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "check_if_array_is_sorted_and_rotated".} =
  if length > 256 or (length > 0 and values.isNil): return -1
  for index in 0 ..< int(length):
    if values[index] < -2147483648 or values[index] > 2147483647: return -1
  if length == 0: return 1
  var descents = 0
  for index in 0 ..< int(length):
    let next = (index + 1) mod int(length)
    if values[index] > values[next]:
      inc descents
      if descents > 1: return 0
  1
