## Deterministic bounded two-level FKS static perfect hashing.
proc hashIndex(a, b, modulus: int, key: int64): int {.inline.} =
  ((a * int(key) + b) mod 257) mod modulus

proc fks_static_perfect_hash*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "fks_static_perfect_hash".} =
  if input.isNil or length < 2 or length > 19: return -1
  let nr = input[0]
  let qr = input[1]
  if nr < 0 or nr > 8 or qr < 0 or qr > 8: return -1
  let n = int(nr)
  let q = int(qr)
  if length != csize_t(2 + n + q): return -1
  for i in 0 ..< n + q:
    if input[2 + i] < 0 or input[2 + i] > 255: return -1
  for i in 0 ..< n:
    for j in i + 1 ..< n:
      if input[2 + i] == input[2 + j]: return -1

  var bucketOf: array[8, int]
  var bucketSizes: array[8, int]
  var firstA = 0
  var firstB = 0
  var firstFound = n == 0
  for a in 1 .. 256:
    if firstFound: break
    for b in 0 .. 256:
      if firstFound: break
      var counts: array[8, int]
      for i in 0 ..< n: inc counts[hashIndex(a, b, n, input[2 + i])]
      var squareSum = 0
      for bucket in 0 ..< n: squareSum += counts[bucket] * counts[bucket]
      if squareSum <= 4 * n:
        firstA = a
        firstB = b
        firstFound = true
  if not firstFound: return -1
  for i in 0 ..< n:
    bucketOf[i] = hashIndex(firstA, firstB, n, input[2 + i])
    inc bucketSizes[bucketOf[i]]

  var slotKeys: array[8, array[64, int64]]
  var occupied: array[8, array[64, bool]]
  var localA, localB: array[8, int]
  for bucket in 0 ..< n:
    let count = bucketSizes[bucket]
    if count == 0: continue
    let capacity = count * count
    var localFound = false
    for a in 1 .. 256:
      if localFound: break
      for b in 0 .. 256:
        if localFound: break
        var used: array[64, bool]
        var collision = false
        for i in 0 ..< n:
          if bucketOf[i] == bucket:
            let position = hashIndex(a, b, capacity, input[2 + i])
            if used[position]:
              collision = true
            else:
              used[position] = true
        if not collision:
          localA[bucket] = a
          localB[bucket] = b
          for i in 0 ..< n:
            if bucketOf[i] == bucket:
              let position = hashIndex(a, b, capacity, input[2 + i])
              slotKeys[bucket][position] = input[2 + i]
              occupied[bucket][position] = true
          localFound = true
    if not localFound: return -1

  var result = 0'i64
  for i in 0 ..< q:
    var present = false
    if n > 0:
      let query = input[2 + n + i]
      let bucket = hashIndex(firstA, firstB, n, query)
      let count = bucketSizes[bucket]
      let capacity = count * count
      if capacity > 0:
        let position = hashIndex(localA[bucket], localB[bucket], capacity, query)
        present = occupied[bucket][position] and slotKeys[bucket][position] == query
    if present: result = result or (1'i64 shl i)
  result
