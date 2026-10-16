proc putI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (byte * 8)) and 255'u64)

proc sortThree(first, second, third: var int64) =
  if first > second: swap(first, second)
  if second > third: swap(second, third)
  if first > second: swap(first, second)

proc triplet_sum*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "triplet_sum".} =
  const MaxItems = 10
  if input == nil or length < 1 or length > MaxItems + 1: return -1
  let target = input[0]
  if target < -3_000_000 or target > 3_000_000: return -1
  let itemCount = int(length - 1)
  for index in 0 ..< itemCount:
    if input[index + 1] < -1_000_000 or input[index + 1] > 1_000_000: return -1
  if outputCapacity < 24 or output == nil: return -2

  var result = [0'i64, 0'i64, 0'i64]
  var found = false
  for first in 0 ..< itemCount:
    if found: break
    for second in 0 ..< itemCount:
      if found: break
      if second == first: continue
      for third in 0 ..< itemCount:
        if third == first or third == second: continue
        let a = input[first + 1]
        let b = input[second + 1]
        let c = input[third + 1]
        if a + b + c == target:
          result = [a, b, c]
          sortThree(result[0], result[1], result[2])
          found = true
          break
  for index in 0 ..< 3: putI64Le(output, index * 8, result[index])
  3
