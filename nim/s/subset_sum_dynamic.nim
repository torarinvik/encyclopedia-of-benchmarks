## Memoized top-down subset existence for signed values.
const MaxItems = 16
const Width = 801
const States = (MaxItems + 1) * Width

proc subsetSumDynamicSearch(input: ptr UncheckedArray[int64], itemCount, index: int,
                            remaining: int64, memo: var array[States, int64]): int64 =
  if remaining == 0: return 1
  if index == itemCount: return 0
  let state = index * Width + int(remaining + 400)
  if memo[state] != -2: return memo[state]
  var result = subsetSumDynamicSearch(input, itemCount, index + 1,
    remaining - input[index + 1], memo)
  if result == 0:
    result = subsetSumDynamicSearch(input, itemCount, index + 1, remaining, memo)
  memo[state] = result
  result

proc subset_sum_dynamic*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "subset_sum_dynamic".} =
  if input.isNil or length == 0 or length > csize_t(MaxItems + 1): return -1
  let target = input[0]
  if target < -80 or target > 80: return -1
  for index in 1 ..< int(length):
    if input[index] < -20 or input[index] > 20: return -1
  var memo: array[States, int64]
  for entry in 0 ..< States: memo[entry] = -2
  subsetSumDynamicSearch(input, int(length) - 1, 0, target, memo)
