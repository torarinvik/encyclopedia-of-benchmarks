proc problem164*(nDigits: int64): int64 {.cdecl, exportc: "problem164".} =
  if nDigits < 0 or nDigits > 26: return -1
  if nDigits == 0: return 1

  var current: array[100, int64]
  var next: array[100, int64]
  for first in 1 .. 9: current[first * 10] = 1

  for used in 1 ..< int(nDigits):
    for index in 0 ..< 100: next[index] = 0
    for previous in 0 .. 9:
      for beforePrevious in 0 .. 9:
        let ways = current[previous * 10 + beforePrevious]
        let maximumDigit = 9 - previous - beforePrevious
        for digit in 0 .. maximumDigit:
          next[digit * 10 + previous] += ways
    for index in 0 ..< 100: current[index] = next[index]

  var total = 0'i64
  for ways in current: total += ways
  total
