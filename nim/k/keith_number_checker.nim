## Preserve the digit-window recurrence used by the pinned C# checker.
proc keith_number_checker*(number: int64): int64 {.cdecl, exportc: "keith_number_checker".} =
  if number < 2 or number > 1000: return -1
  let original = number
  var temp = number
  var digits = 0'i64
  while temp != 0:
    inc digits
    temp = temp div 10

  var terms = newSeq[int64](int(number))
  temp = number
  var i = digits
  while i > 0:
    dec i
    terms[int(i)] = temp mod 10
    temp = temp div 10

  var sum = 0'i64
  var k = digits
  while sum < original:
    sum = 0
    for j in 1'i64 .. digits: sum += terms[int(k - j)]
    terms[int(k)] = sum
    inc k
  return (if sum == original: 1'i64 else: 0'i64)
