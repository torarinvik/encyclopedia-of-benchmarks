proc integerSqrtI64(value, upper: int64): int64 =
  var low = 0'i64
  var high = upper + 1
  while low + 1 < high:
    let middle = low + (high - low) div 2
    if middle * middle <= value: low = middle
    else: high = middle
  low

proc fermat_factorization*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "fermat_factorization".} =
  if input == nil or length != 2: return -1
  let number = input[0]
  let maxSteps = input[1]
  if number < 3 or number > 1_000_000_000_000'i64 or number mod 2 == 0
      or maxSteps < 0 or maxSteps > 4096: return -1
  var candidate = integerSqrtI64(number, 1_000_000)
  if candidate * candidate < number: inc candidate
  var step = 0'i64
  while step < maxSteps:
    let difference = candidate * candidate - number
    let root = integerSqrtI64(difference, candidate)
    if root * root == difference:
      let factor = candidate - root
      if factor > 1 and factor < number: return factor
    inc candidate
    inc step
  0
