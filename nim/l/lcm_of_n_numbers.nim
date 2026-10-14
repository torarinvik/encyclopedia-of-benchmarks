## Fold a list of nonnegative values with overflow-safe Euclidean LCM.
proc lcm_of_n_numbers*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "lcm_of_n_numbers".} =
  var index = csize_t(0)
  while index < length:
    if values[index] == 0:
      return 0
    inc index
  var accumulator = 1'u64
  let maximum = uint64(high(int64))
  index = 0
  while index < length:
    let value = uint64(values[index])
    var left = accumulator
    var right = value
    while right != 0:
      let remainder = left mod right
      left = right
      right = remainder
    let reduced = accumulator div left
    if reduced > maximum div value:
      return -1
    accumulator = reduced * value
    inc index
  int64(accumulator)
