## Decide whether a signed integer subset reaches the requested sum.
proc subset_sum_exists*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "subset_sum_exists".} =
  if length == 0 or length > 25: return -1
  let target = input[0]
  if target < -6144 or target > 6144: return -1
  for index in 1 ..< length:
    if input[index] < -256 or input[index] > 256: return -1

  var reachable: array[12289, bool]
  reachable[6144] = true
  var low = 0'i64
  var high = 0'i64
  for index in 1 ..< length:
    let value = input[index]
    if value > 0:
      var sum = high
      while sum >= low:
        if reachable[int(sum + 6144)]: reachable[int(sum + value + 6144)] = true
        dec sum
      high += value
    elif value < 0:
      var sum = low
      while sum <= high:
        if reachable[int(sum + 6144)]: reachable[int(sum + value + 6144)] = true
        inc sum
      low += value
  if reachable[int(target + 6144)]: 1'i64 else: 0'i64
