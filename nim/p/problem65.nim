const MaxDigits = 256

proc problem65*(maxN: int64): int64 {.cdecl, exportc: "problem65".} =
  if maxN < 1 or maxN > 100: return -1
  var previous: array[MaxDigits, int64]
  var current: array[MaxDigits, int64]
  var next: array[MaxDigits, int64]
  previous[0] = 1
  current[0] = 2
  var previousLength = 1
  var currentLength = 1
  var i: int64 = 2
  while i <= maxN:
    let coefficient = if i mod 3 == 0: (2 * i) div 3 else: 1'i64
    var carry: int64 = 0
    for position in 0..<currentLength:
      let old = if position < previousLength: previous[position] else: 0'i64
      let total = coefficient * current[position] + old + carry
      next[position] = total mod 10
      carry = total div 10
    var nextLength = currentLength
    while carry != 0:
      next[nextLength] = carry mod 10
      inc nextLength
      carry = carry div 10
    for position in 0..<currentLength: previous[position] = current[position]
    for position in 0..<nextLength: current[position] = next[position]
    previousLength = currentLength
    currentLength = nextLength
    inc i
  var digitSum: int64 = 0
  for position in 0..<currentLength: digitSum += current[position]
  digitSum
