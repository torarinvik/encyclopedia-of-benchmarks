const MaxInput = 9_999_999_999_999_999'i64

proc nextFor(number: int64): int64 =
  var digits: array[17, uint8]
  var remaining = number
  var count = 0
  while true:
    digits[count] = uint8(remaining mod 10)
    inc count
    remaining = remaining div 10
    if remaining == 0: break

  for left in 0 ..< count div 2:
    let right = count - 1 - left
    swap(digits[left], digits[right])
  for left in 0 ..< count div 2:
    digits[count - 1 - left] = digits[left]
  var candidate = 0'i64
  for i in 0 ..< count: candidate = candidate * 10 + int64(digits[i])
  if candidate > number: return candidate

  var position = (count + 1) div 2
  while position > 0 and digits[position - 1] == 9'u8:
    digits[position - 1] = 0'u8
    dec position
  if position == 0:
    var power = 1'i64
    for _ in 0 ..< count: power *= 10
    return power + 1
  inc digits[position - 1]
  for left in 0 ..< count div 2:
    digits[count - 1 - left] = digits[left]
  candidate = 0
  for i in 0 ..< count: candidate = candidate * 10 + int64(digits[i])
  candidate

proc next_palindromic_number*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "next_palindromic_number".} =
  if values.isNil or length != csize_t(1): return -1
  let number = values[0]
  if number < 0 or number > MaxInput: return -1
  nextFor(number)
