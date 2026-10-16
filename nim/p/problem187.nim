proc isComposite(bits: seq[uint64], value: int64): bool =
  ((bits[int(value shr 6)] shr int(value and 63)) and 1'u64) != 0

proc markComposite(bits: var seq[uint64], value: int64) =
  bits[int(value shr 6)] = bits[int(value shr 6)] or (1'u64 shl int(value and 63))

proc problem187*(maxNumber: int64): int64 {.cdecl, exportc: "problem187".} =
  if maxNumber < 0 or maxNumber > 100_000_000: return -1
  let primeLimit = maxNumber div 2
  if primeLimit <= 2: return 0
  var composite = newSeq[uint64](int((primeLimit + 63) div 64))
  markComposite(composite, 0)
  markComposite(composite, 1)
  var prime = 2'i64
  while prime <= (primeLimit - 1) div prime:
    if not isComposite(composite, prime):
      var multiple = prime * prime
      while multiple < primeLimit:
        markComposite(composite, multiple)
        multiple += prime
    inc prime

  var rightValue = primeLimit - 1
  while rightValue >= 2 and isComposite(composite, rightValue): dec rightValue
  if rightValue < 2: return 0
  var primeCount = 0'i64
  for value in 2'i64 .. rightValue:
    if not isComposite(composite, value): inc primeCount

  var rightRank = primeCount - 1
  var leftRank = 0'i64
  var count = 0'i64
  for leftValue in 2'i64 .. rightValue:
    if isComposite(composite, leftValue): continue
    while rightRank >= leftRank and leftValue * rightValue >= maxNumber:
      dec rightRank
      dec rightValue
      while rightValue >= 2 and isComposite(composite, rightValue): dec rightValue
    if rightRank < leftRank: break
    count += rightRank - leftRank + 1
    inc leftRank
  count
