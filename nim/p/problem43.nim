proc nextPermutation(digits: var array[10, int]): bool =
  var i = 8
  while i >= 0 and digits[i] >= digits[i + 1]: dec i
  if i < 0: return false
  var j = 9
  while digits[j] <= digits[i]: dec j
  swap(digits[i], digits[j])
  var left = i + 1
  var right = 9
  while left < right:
    swap(digits[left], digits[right]); inc left; dec right
  true

proc problem43*(n: int64): int64 {.cdecl, exportc: "problem43".} =
  if n != 10: return -1
  var digits: array[10, int]
  for i in 0 .. 9: digits[i] = i
  const divisors = [7, 11, 13, 17]
  var total = 0'i64
  var more = true
  while more:
    if digits[3] mod 2 == 0 and (digits[2]+digits[3]+digits[4]) mod 3 == 0 and digits[5] mod 5 == 0:
      var valid = true
      for i in 0 .. 3:
        if (digits[i+4]*100+digits[i+5]*10+digits[i+6]) mod divisors[i] != 0: valid = false
      if valid:
        var value = 0'i64
        for digit in digits: value = value*10+int64(digit)
        total += value
    more = nextPermutation(digits)
  total
