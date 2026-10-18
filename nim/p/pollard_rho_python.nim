const MaxNum = 1_000_000'i64

proc gcdNonnegative(leftValue, rightValue: int64): int64 =
  var left = leftValue
  var right = rightValue
  while right != 0:
    let remainder = left mod right
    left = right
    right = remainder
  left

proc advance(value, step, modulus: int64): int64 =
  (value * value + step) mod modulus

proc pollardRhoPython*(input: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "pollard_rho_python".} =
  if input == nil or length != 5: return -1
  let num = input[0]
  var seed = input[1]
  var step = input[2]
  let attempts = input[3]
  let stepLimit = input[4]
  if num < 2 or num > MaxNum or seed < 0 or seed >= num or step < 0 or step > 1000 or attempts < 1 or attempts > 8 or stepLimit < 1 or stepLimit > 64: return -1
  if num > 2 and num mod 2 == 0: return 2

  for _ in 0'i64 ..< attempts:
    var tortoise = seed
    var hare = seed
    for _ in 0'i64 ..< stepLimit:
      tortoise = advance(tortoise, step, num)
      hare = advance(advance(hare, step, num), step, num)
      let difference = if hare >= tortoise: hare - tortoise else: tortoise - hare
      let divisor = gcdNonnegative(difference, num)
      if divisor == 1: continue
      if divisor < num: return divisor
      break
    seed = hare
    inc step
  0
