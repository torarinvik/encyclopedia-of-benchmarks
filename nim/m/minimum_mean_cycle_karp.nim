## Karp's exact-length dynamic program for a bounded directed graph.
proc storeI64Le(output: var array[16, uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc ratioLess(aNum, aDen, bNum, bDen: int64): bool =
  aNum * bDen < bNum * aDen

proc gcdPositive(aValue, bValue: int64): int64 =
  var a = aValue
  var b = bValue
  while b != 0:
    let remainder = a mod b
    a = b
    b = remainder
  a

proc allReachable(n: int, adjacent: array[64, bool], reverse: bool): bool =
  var seen: array[8, bool]
  var queue: array[8, int]
  var head = 0
  var tail = 1
  seen[0] = true
  queue[0] = 0
  while head < tail:
    let u = queue[head]
    inc head
    for v in 0 ..< n:
      let slot = if reverse: v * 8 + u else: u * 8 + v
      if adjacent[slot] and not seen[v]:
        seen[v] = true
        queue[tail] = v
        inc tail
  for v in 0 ..< n:
    if not seen[v]: return false
  true

proc minimum_mean_cycle_karp*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "minimum_mean_cycle_karp".} =
  if input == nil or length < 2 or length > 51: return -1
  let nValue = input[0]
  let mValue = input[1]
  if nValue < 1 or nValue > 8 or mValue < 1 or mValue > 16: return -1
  let n = int(nValue)
  let m = int(mValue)
  if m > n * n or int(length) != 2 + 3 * m: return -1

  var edgeFrom: array[16, int]
  var edgeTo: array[16, int]
  var edgeWeight: array[16, int64]
  var adjacent: array[64, bool]
  for edge in 0 ..< m:
    let uValue = input[2 + 3 * edge]
    let vValue = input[3 + 3 * edge]
    let weight = input[4 + 3 * edge]
    if uValue < 0 or uValue >= nValue or vValue < 0 or vValue >= nValue or weight < -1000 or weight > 1000: return -1
    let u = int(uValue)
    let v = int(vValue)
    let slot = u * 8 + v
    if adjacent[slot]: return -1
    adjacent[slot] = true
    edgeFrom[edge] = u
    edgeTo[edge] = v
    edgeWeight[edge] = weight
  if not allReachable(n, adjacent, false) or not allReachable(n, adjacent, true): return -1
  if output == nil or outputCapacity < 16: return -2

  var cost: array[72, int64]
  var reachable: array[72, bool]
  reachable[0] = true
  for k in 1 .. n:
    for edge in 0 ..< m:
      let u = edgeFrom[edge]
      let v = edgeTo[edge]
      let previous = (k - 1) * 8 + u
      let current = k * 8 + v
      if not reachable[previous]: continue
      let candidate = cost[previous] + edgeWeight[edge]
      if not reachable[current] or candidate < cost[current]:
        reachable[current] = true
        cost[current] = candidate

  var haveAnswer = false
  var answerNum = 0'i64
  var answerDen = 1'i64
  for v in 0 ..< n:
    if not reachable[n * 8 + v]: continue
    var haveLocal = false
    var localNum = 0'i64
    var localDen = 1'i64
    for k in 0 ..< n:
      let slot = k * 8 + v
      if not reachable[slot]: continue
      let numerator = cost[n * 8 + v] - cost[slot]
      let denominator = int64(n - k)
      if not haveLocal or ratioLess(localNum, localDen, numerator, denominator):
        localNum = numerator
        localDen = denominator
        haveLocal = true
    if haveLocal and (not haveAnswer or ratioLess(localNum, localDen, answerNum, answerDen)):
      answerNum = localNum
      answerDen = localDen
      haveAnswer = true
  if not haveAnswer: return -1
  let divisor = gcdPositive(abs(answerNum), answerDen)
  answerNum = answerNum div divisor
  answerDen = answerDen div divisor
  var staged: array[16, uint8]
  storeI64Le(staged, 0, answerNum)
  storeI64Le(staged, 8, answerDen)
  for byte in 0 ..< 16: output[byte] = staged[byte]
  16
