const Logins: array[50, int] = [
  319, 680, 180, 690, 129, 620, 762, 689, 762, 318,
  368, 710, 720, 710, 629, 168, 160, 689, 716, 731,
  736, 729, 316, 729, 729, 710, 769, 290, 719, 680,
  318, 389, 162, 289, 162, 718, 729, 319, 790, 680,
  890, 362, 319, 760, 316, 729, 380, 319, 728, 716
]

proc nextPermutation(digits: var array[10, int], length: int): bool =
  var pivot = length - 2
  while pivot >= 0 and digits[pivot] >= digits[pivot + 1]: dec pivot
  if pivot < 0: return false
  var successor = length - 1
  while digits[successor] <= digits[pivot]: dec successor
  swap(digits[pivot], digits[successor])
  var left = pivot + 1
  var right = length - 1
  while left < right:
    swap(digits[left], digits[right])
    inc left
    dec right
  true

proc problem79*(placeholder: int64): int64 {.cdecl, exportc: "problem79".} =
  if placeholder != 0: return -1
  var present: array[10, bool]
  for login in Logins:
    present[login div 100] = true
    present[(login div 10) mod 10] = true
    present[login mod 10] = true
  var digits: array[10, int]
  var length = 0
  for digit in 0..9:
    if present[digit]:
      digits[length] = digit
      inc length
  while true:
    var positions: array[10, int]
    for digit in 0..9: positions[digit] = -1
    for i in 0..<length: positions[digits[i]] = i
    var satisfied = true
    for login in Logins:
      let first = login div 100
      let second = (login div 10) mod 10
      let third = login mod 10
      if not (positions[first] < positions[second] and positions[second] < positions[third]):
        satisfied = false
        break
    if satisfied:
      var passcode = 0'i64
      for i in 0..<length: passcode = passcode * 10 + int64(digits[i])
      return passcode
    if not nextPermutation(digits, length): break
  -1
