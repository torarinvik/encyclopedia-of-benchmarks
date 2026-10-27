const MaxN = 32
const MaxQ = 32
const Bucket = 3
const MaxB = 11
const MaxWords = 100

proc lcp(a, b: int64): int =
  var count = 0
  while count < 16 and ((a shr (15 - count)) and 1) == ((b shr (15 - count)) and 1):
    inc count
  count

proc putI64(outp: ptr UncheckedArray[uint8], pos: int, value: int64) =
  let bits = cast[uint64](value)
  for b in 0 ..< 8: outp[pos + b] = uint8((bits shr (8 * b)) and 255)

proc mmpfhBucketing(input: ptr UncheckedArray[int64], length: csize_t,
                    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
                    {.cdecl, exportc: "mmpfh_bucketing".} =
  if input.isNil or length < 3 or length > 66: return -1
  let n0 = input[0]; let q0 = input[1]
  if n0 < 1 or n0 > MaxN or q0 < 1 or q0 > MaxQ or length != csize_t(2 + n0 + q0): return -1
  let n = int(n0); let q = int(q0)
  var keys: array[MaxN, int64]
  var queries: array[MaxQ, int64]
  for i in 0 ..< n:
    let x = input[2 + i]
    if x < 0 or x > 65535 or (i > 0 and keys[i - 1] >= x): return -1
    keys[i] = x
  for i in 0 ..< q:
    let x = input[2 + n + i]
    if x < 0 or x > 65535: return -1
    queries[i] = x
    var found = false
    for j in 0 ..< n:
      if keys[j] == x: found = true
    if not found: return -1
  let buckets = (n + Bucket - 1) div Bucket
  var d0: array[MaxN, int64]
  var lengths, prefixes: array[MaxB, int64]
  var ranks: array[MaxQ, int64]
  for b in 0 ..< buckets:
    let start = b * Bucket
    let finish = min(start + Bucket, n)
    let plen = if finish - start == 1: 16 else: lcp(keys[start], keys[finish - 1])
    let prefix = if plen == 0: 0'i64 else: keys[start] shr (16 - plen)
    lengths[b] = int64(plen); prefixes[b] = prefix
    for i in start ..< finish: d0[i] = int64(plen)
  for i in 0 ..< q:
    var pos = 0
    while keys[pos] != queries[i]: inc pos
    let plen = int(d0[pos])
    let prefix = if plen == 0: 0'i64 else: queries[i] shr (16 - plen)
    var b = 0
    while b < buckets and (lengths[b] != d0[pos] or prefixes[b] != prefix): inc b
    if b == buckets: return -1
    ranks[i] = int64(b * Bucket + pos - b * Bucket)
  let words = 3 + n + 3 * buckets + q
  if output.isNil or capacity < csize_t(words * 8): return -2
  var staged: array[MaxWords, int64]
  var k = 0
  staged[k] = int64(n); inc k; staged[k] = int64(buckets); inc k; staged[k] = int64(q); inc k
  for i in 0 ..< n: staged[k] = d0[i]; inc k
  for b in 0 ..< buckets:
    staged[k] = lengths[b]; inc k; staged[k] = prefixes[b]; inc k; staged[k] = int64(b); inc k
  for i in 0 ..< q: staged[k] = ranks[i]; inc k
  for i in 0 ..< words: putI64(output, i * 8, staged[i])
  int64(words * 8)
