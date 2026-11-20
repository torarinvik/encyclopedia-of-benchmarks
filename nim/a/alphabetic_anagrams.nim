const MaxLength = 8
const AlphabetSize = 26
const MaxParseableLength = 10

proc factorial(value: int64): int64 =
  result = 1
  for factor in 2'i64 .. value: result *= factor

proc alphabetic_anagrams*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "alphabetic_anagrams".} =
  if input.isNil or length < csize_t(1) or length > csize_t(MaxParseableLength): return -1
  let nValue = input[0]
  if nValue < 0 or nValue > MaxLength or length != csize_t(nValue + 1): return -1
  let n = int(nValue)
  var frequency: array[AlphabetSize, int64]
  for position in 0 ..< n:
    let symbol = input[position + 1]
    if symbol < 0 or symbol > 25: return -1
    inc frequency[int(symbol)]

  var denominator = 1'i64
  for count in frequency: denominator *= factorial(count)
  var ways = factorial(nValue) div denominator
  var rank = 1'i64
  var remaining = nValue
  for position in 0 ..< n:
    let actual = int(input[position + 1])
    for smaller in 0 ..< actual:
      if frequency[smaller] > 0:
        rank += ways * frequency[smaller] div remaining
    ways = ways * frequency[actual] div remaining
    dec frequency[actual]
    dec remaining
  rank
