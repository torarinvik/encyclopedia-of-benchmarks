const minBase = 3'i64
const maxBase = 16'i64
const maxDigits = 10'i64
const maxLimit = 100_000'i64
const maxParseableLength = 3
const maxQueue = 70_000

proc leftTruncatableIsPrime(value: int64): bool =
  if value < 2: return false
  if value mod 2 == 0: return value == 2
  var divisor = 3'i64
  while divisor * divisor <= value:
    if value mod divisor == 0: return false
    divisor += 2
  true

proc leftTruncatableSearch(base, digits: int64): int64 =
  var queue: array[maxQueue, int64]
  var ending = 0
  for value in 2'i64 ..< base:
    if leftTruncatableIsPrime(value):
      queue[ending] = value
      inc ending
  var best = queue[ending - 1]
  var levelStart = 0
  var levelEnd = ending
  var place = base
  var width = 1'i64
  while width < digits and levelStart < levelEnd:
    for index in levelStart ..< levelEnd:
      let suffix = queue[index]
      for leading in 1'i64 ..< base:
        let candidate = leading * place + suffix
        if leftTruncatableIsPrime(candidate):
          if ending >= maxQueue: return -1
          queue[ending] = candidate
          inc ending
          if candidate > best: best = candidate
    levelStart = levelEnd
    levelEnd = ending
    place *= base
    inc width
  best

proc left_truncatable_prime_search*(input: ptr UncheckedArray[int64],
    length: csize_t): int64 {.cdecl, exportc: "left_truncatable_prime_search".} =
  if input.isNil or length < 2 or length > csize_t(maxParseableLength): return -1
  let base = input[0]
  let digits = input[1]
  if length != 2 or base < minBase or base > maxBase or digits < 1 or digits > maxDigits: return -1
  var limit = 1'i64
  for _ in 0 ..< digits: limit *= base
  if limit > maxLimit: return -1
  leftTruncatableSearch(base, digits)
