const Limbs = 16
const Base = 1_000_000_000'u64
type Big = array[Limbs, uint64]
proc mulAdd(src: Big, factor, add: uint64, dst: var Big) =
  var carry = add
  for i in 0 ..< Limbs:
    let value = src[i] * factor + carry
    dst[i] = value mod Base
    carry = value div Base
proc ge(left, right: Big): bool =
  for i in countdown(Limbs - 1, 0):
    if left[i] != right[i]: return left[i] > right[i]
  true
proc subtract(left: var Big, right: Big) =
  var borrow = 0'u64
  for i in 0 ..< Limbs:
    let amount = right[i] + borrow
    if left[i] < amount:
      left[i] = left[i] + Base - amount
      borrow = 1
    else:
      left[i] -= amount
      borrow = 0
proc problem80*(placeholder: int64): int64 {.cdecl, exportc: "problem80".} =
  if placeholder != 0: return -1
  var answer = 0'i64
  for number in 2'u64 ..< 100'u64:
    var integerRoot = 0'u64
    while (integerRoot + 1) * (integerRoot + 1) <= number: inc integerRoot
    if integerRoot * integerRoot == number: continue
    var root, remainder, scaled, trial: Big
    var digitSum = 0'i64
    for step in 0 ..< 100:
      mulAdd(remainder, 100, (if step == 0: number else: 0), remainder)
      var digit = 9'i64
      while digit >= 0:
        mulAdd(root, 20, digit.uint64, scaled)
        mulAdd(scaled, digit.uint64, 0, trial)
        if ge(remainder, trial): break
        dec digit
      subtract(remainder, trial)
      mulAdd(root, 10, digit.uint64, root)
      digitSum += digit
    answer += digitSum
  answer
