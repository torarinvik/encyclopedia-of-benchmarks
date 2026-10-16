proc nextPermutation(digits: var array[9, int]): bool =
  var pivot = 7
  while pivot >= 0 and digits[pivot] >= digits[pivot + 1]: dec pivot
  if pivot < 0: return false
  var successor = 8
  while digits[successor] <= digits[pivot]: dec successor
  swap(digits[pivot], digits[successor])
  var left = pivot + 1
  var right = 8
  while left < right:
    swap(digits[left], digits[right])
    inc left
    dec right
  true

proc problem32*(ignored: int64): int64 {.cdecl, exportc: "problem32".} =
  if ignored != 0: return -1
  var digits = [1, 2, 3, 4, 5, 6, 7, 8, 9]
  var seen: array[10000, bool]
  while true:
    let product = digits[5] * 1000 + digits[6] * 100 + digits[7] * 10 + digits[8]
    let twoDigit = digits[0] * 10 + digits[1]
    let threeDigit = digits[2] * 100 + digits[3] * 10 + digits[4]
    let fourDigit = digits[1] * 1000 + digits[2] * 100 + digits[3] * 10 + digits[4]
    if twoDigit * threeDigit == product or digits[0] * fourDigit == product:
      seen[product] = true
    if not nextPermutation(digits): break
  var sum = 0'i64
  for product in 0..<seen.len:
    if seen[product]: sum += product.int64
  sum
