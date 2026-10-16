proc problem25*(requestedDigits: int64): int64 {.cdecl, exportc: "problem25".} =
  if requestedDigits < 2 or requestedDigits > 1000: return -1
  var previous: array[1000, int]
  var current: array[1000, int]
  var next: array[1000, int]
  previous[0] = 1
  current[0] = 1
  var activeDigits = 1
  var index = 2'i64
  while activeDigits < int(requestedDigits):
    var carry = 0
    for position in 0..<activeDigits:
      let total = previous[position] + current[position] + carry
      next[position] = total mod 10
      carry = total div 10
    if carry != 0:
      next[activeDigits] = carry
      inc activeDigits
    for position in 0..<activeDigits:
      previous[position] = current[position]
      current[position] = next[position]
    inc index
  index
