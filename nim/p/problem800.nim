import std/math

proc isComposite(bits: seq[uint64], value: int64): bool =
  ((bits[int(value shr 6)] shr int(value and 63)) and 1'u64) != 0

proc markComposite(bits: var seq[uint64], value: int64) =
  bits[int(value shr 6)] = bits[int(value shr 6)] or (1'u64 shl int(value and 63))

proc problem800*(base, degree: int64): int64 {.cdecl, exportc: "problem800".} =
  if base < 2 or base > 1_000_000 or degree < 1 or degree > 1_000_000: return -1
  let upperBound = float64(degree) * log2(float64(base))
  let primeLimit = int64(upperBound)
  if primeLimit <= 2: return 0
  var composite = newSeq[uint64](int((primeLimit + 63) div 64))
  var prime = 2'i64
  while prime <= (primeLimit - 1) div prime:
    if not isComposite(composite, prime):
      var multiple = prime * prime
      while multiple < primeLimit:
        markComposite(composite, multiple)
        multiple += prime
    inc prime

  var rightValue = 0'i64
  var primeCount = 0'i64
  for value in 2'i64 ..< primeLimit:
    if not isComposite(composite, value):
      rightValue = value
      inc primeCount
  if primeCount < 2: return 0

  var rightRank = primeCount - 1
  var leftRank = 0'i64
  var leftValue = 2'i64
  var count = 0'i64
  while leftRank < rightRank:
    while isComposite(composite, leftValue): inc leftValue
    let leftLog = log2(float64(leftValue))
    while float64(rightValue) * leftLog + float64(leftValue) * log2(float64(rightValue)) > upperBound:
      dec rightRank
      dec rightValue
      while rightValue >= 2 and isComposite(composite, rightValue): dec rightValue
    count += rightRank - leftRank
    inc leftRank
    inc leftValue
  count
