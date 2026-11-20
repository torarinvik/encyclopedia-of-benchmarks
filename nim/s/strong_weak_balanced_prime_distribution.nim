const maxLimit = 100_000'i64
const sieveLength = 200_001
const maxParseableLength = 2

proc strong_weak_balanced_prime_distribution*(input: ptr UncheckedArray[int64],
    length: csize_t): int64 {.cdecl, exportc: "strong_weak_balanced_prime_distribution".} =
  if input.isNil or length < 1 or length > csize_t(maxParseableLength): return -1
  let limit = input[0]
  if length != 1 or limit < 3 or limit > maxLimit: return -1

  let ceiling = 2 * limit
  var prime: array[sieveLength, bool]
  for index in 0 ..< sieveLength: prime[index] = true
  prime[0] = false
  prime[1] = false
  var divisor = 2'i64
  while divisor * divisor <= ceiling:
    if prime[int(divisor)]:
      var multiple = divisor * divisor
        while multiple <= ceiling:
        prime[int(multiple)] = false
        multiple += divisor
    inc divisor

  var strong, weak, balanced = 0'i64
  var previous, current = 0'i64
  var candidate = 2'i64
  while candidate <= ceiling:
    if prime[int(candidate)]:
      if previous != 0 and current >= 3 and current <= limit:
        let twice = 2 * current
        let neighbors = previous + candidate
        if twice > neighbors: inc strong
        elif twice < neighbors: inc weak
        else: inc balanced
      previous = current
      current = candidate
    inc candidate
  strong * 10_000_000_000'i64 + weak * 100_000'i64 + balanced
