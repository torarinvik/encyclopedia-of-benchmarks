## Count indexed signed subsets that reach the requested sum.
proc subset_sum_count*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "subset_sum_count".} =
  if length == 0 or length > 25: return -1
  let target = input[0]
  if target < -6144 or target > 6144: return -1
  for index in 1 ..< length:
    if input[index] < -256 or input[index] > 256: return -1

  var ways: array[12289, int64]
  ways[6144] = 1
  var low = 0'i64
  var high = 0'i64
  for index in 1 ..< length:
    let value = input[index]
    if value > 0:
      var sum = high
      while sum >= low:
        ways[int(sum + value + 6144)] += ways[int(sum + 6144)]
        dec sum
      high += value
    elif value < 0:
      var sum = low
      while sum <= high:
        ways[int(sum + value + 6144)] += ways[int(sum + 6144)]
        inc sum
      low += value
    else:
      var sum = low
      while sum <= high:
        ways[int(sum + 6144)] *= 2
        inc sum
  ways[int(target + 6144)]
