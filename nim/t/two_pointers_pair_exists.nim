const MaxInput = 258

proc two_pointers_pair_exists*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "two_pointers_pair_exists".} =
  if input.isNil or length < 2 or length > MaxInput: return -1
  let target = input[0]
  let n = input[1]
  if n < 0 or n > 256 or length != csize_t(2 + n): return -1
  if target < -2000000 or target > 2000000: return -1
  for i in 0 ..< int(n):
    let value = input[2 + i]
    if value < -1000000 or value > 1000000: return -1
    if i > 0 and input[1 + i] > value: return -1
  if n < 2: return 0
  var left = 0
  var right = int(n) - 1
  while left < right:
    let sum = input[2 + left] + input[2 + right]
    if sum == target: return 1
    if sum < target: inc left
    else: dec right
  0
