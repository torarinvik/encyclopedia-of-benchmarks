## Compare lowercase ASCII alphanumeric strings in natural order.

proc isDigit(value: int64): bool = value >= 48 and value <= 57
proc validString(input: ptr UncheckedArray[int64], start, count: int): bool =
  for i in 0 ..< count:
    let value = input[start + i]
    if not isDigit(value) and (value < 97 or value > 122): return false
    if value == 48 and i > 0 and isDigit(input[start + i - 1]): return false
  true

proc alpha_numerical_sort*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "alpha_numerical_sort".} =
  if input == nil or length < 2 or input[0] < 0 or input[0] > 64: return -2
  let firstLength = int(input[0])
  if csize_t(1 + firstLength) >= length or input[1 + firstLength] < 0 or input[1 + firstLength] > 64: return -2
  let secondLength = int(input[1 + firstLength])
  if length != csize_t(2 + firstLength + secondLength) or
      not validString(input, 2, firstLength) or not validString(input, 2 + firstLength, secondLength): return -2
  var i = 0
  var j = 0
  while i < firstLength and j < secondLength:
    let a = input[2 + i]
    let b = input[2 + firstLength + j]
    if isDigit(a) and isDigit(b):
      var endA = i
      var endB = j
      while endA < firstLength and isDigit(input[2 + endA]): inc endA
      while endB < secondLength and isDigit(input[2 + firstLength + endB]): inc endB
      let digitsA = endA - i
      let digitsB = endB - j
      if digitsA != digitsB: return (if digitsA < digitsB: -1 else: 1)
      for k in 0 ..< digitsA:
        let ca = input[2 + i + k]
        let cb = input[2 + firstLength + j + k]
        if ca != cb: return (if ca < cb: -1 else: 1)
      i = endA
      j = endB
    else:
      if a != b: return (if a < b: -1 else: 1)
      inc i
      inc j
  if i == firstLength and j == secondLength: return 0
  if i == firstLength: return -1
  1
