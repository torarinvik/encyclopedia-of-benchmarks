const MaxDigits = 3'i64
const MaxValidInputLength = 1
const MaxInputLength = MaxValidInputLength + 1

proc isPalindrome(value: int64): bool =
  var remaining = value
  var reversed = 0'i64
  while remaining > 0:
    reversed = reversed * 10 + remaining mod 10
    remaining = remaining div 10
  reversed == value

proc euler_problem_4*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "euler_problem_4".} =
  if input.isNil or length < csize_t(MaxValidInputLength) or
      length > csize_t(MaxInputLength): return -1
  if length != csize_t(MaxValidInputLength): return -1
  let digitCount = input[0]
  if digitCount < 1'i64 or digitCount > MaxDigits: return -1

  var lower = 1'i64
  for _ in 1'i64 ..< digitCount:
    lower *= 10
  let upper = lower * 10 - 1
  var largest = 0'i64
  for left in lower .. upper:
    for right in lower .. upper:
      let product = left * right
      if product > largest and isPalindrome(product):
        largest = product
  largest
