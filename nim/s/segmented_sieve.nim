proc putI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0..<8: output[offset + byte] = uint8((bits shr (8 * byte)) and 0xFF'u64)

proc segmented_sieve*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "segmented_sieve".} =
  if input.isNil or length != 1 or input[0] < 2 or input[0] > 10_000: return -1
  let n = int(input[0])
  var endValue = 0
  while (endValue + 1) * (endValue + 1) <= n: inc endValue
  var baseMarks: array[101, bool]
  var base: array[25, int64]
  var baseCount = 0
  for i in 2..endValue: baseMarks[i] = true
  for p in 2..endValue:
    if not baseMarks[p]: continue
    base[baseCount] = int64(p)
    inc baseCount
    var multiple = p * p
    while multiple <= endValue:
      baseMarks[multiple] = false
      multiple += p
  var primes: array[1229, int64]
  var primeCount = 0
  for i in 0..<baseCount:
    primes[primeCount] = base[i]
    inc primeCount
  var low = endValue + 1
  var high = min(2 * endValue, n)
  while low <= n:
    var segment: array[201, bool]
    let segmentLength = high - low + 1
    for i in 0..<segmentLength: segment[i] = true
    for i in 0..<baseCount:
      let p = int(base[i])
      var first = (low div p) * p
      if first < low: first += p
      while first <= high:
        segment[first - low] = false
        first += p
    for i in 0..<segmentLength:
      if segment[i]:
        primes[primeCount] = int64(low + i)
        inc primeCount
    low = high + 1
    high = min(high + endValue, n)
  let outputLength = primeCount * 8
  if capacity < csize_t(outputLength) or (outputLength > 0 and output.isNil): return -2
  for i in 0..<primeCount: putI64Le(output, i * 8, primes[i])
  int64(outputLength)
