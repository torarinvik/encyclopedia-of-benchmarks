const
  MaxOps = 40
  MaxWords = 82
  KeyCount = 256

type Table = object
  directory: array[KeyCount, uint8]
  keys: array[KeyCount, array[2, uint8]]
  counts, depths: array[KeyCount, uint8]
  active: array[KeyCount, bool]
  gd, highDepth, buckets, live: int

proc initTable(): Table =
  result.gd = 1; result.highDepth = 1; result.buckets = 2
  result.active[0] = true; result.active[1] = true
  result.depths[0] = 1; result.depths[1] = 1
  result.directory[0] = 0; result.directory[1] = 1

proc bucketFor(t: Table, key: int): int = int(t.directory[key and ((1 shl t.gd) - 1)])

proc findSlot(t: Table, bucket, key: int): int =
  for slot in 0 ..< int(t.counts[bucket]):
    if int(t.keys[bucket][slot]) == key: return slot
  -1

proc split(t: var Table, bucket: int): bool =
  let d = int(t.depths[bucket])
  if d >= 8: return false
  if d == t.gd:
    let oldSize = 1 shl t.gd
    for i in 0 ..< oldSize: t.directory[i + oldSize] = t.directory[i]
    inc t.gd
    t.highDepth = max(t.highDepth, t.gd)
  var fresh = 0
  while fresh < KeyCount and t.active[fresh]: inc fresh
  if fresh == KeyCount: return false
  t.active[fresh] = true
  t.depths[bucket] = uint8(d + 1); t.depths[fresh] = uint8(d + 1)
  let oldCount = int(t.counts[bucket]); let oldKeys = t.keys[bucket]
  t.counts[bucket] = 0; t.counts[fresh] = 0
  t.keys[bucket] = [0'u8, 0'u8]; t.keys[fresh] = [0'u8, 0'u8]
  let bit = 1 shl d; let size = 1 shl t.gd
  for i in 0 ..< size:
    if int(t.directory[i]) == bucket and (i and bit) != 0: t.directory[i] = uint8(fresh)
  for j in 0 ..< oldCount:
    let key = int(oldKeys[j]); let target = if (key and bit) != 0: fresh else: bucket
    t.keys[target][int(t.counts[target])] = oldKeys[j]
    inc t.counts[target]
  inc t.buckets
  true

proc coalesce(t: var Table, startBucket: int) =
  var bucket = startBucket
  while t.depths[bucket] > 1:
    let d = int(t.depths[bucket]); let size = 1 shl t.gd
    var representative = -1
    for i in 0 ..< size:
      if int(t.directory[i]) == bucket: representative = i; break
    if representative < 0: break
    let prefix = representative and ((1 shl d) - 1)
    let buddyPrefix = prefix xor (1 shl (d - 1)); let buddy = int(t.directory[buddyPrefix])
    if buddy == bucket or not t.active[buddy] or t.depths[buddy] != uint8(d) or int(t.counts[bucket]) + int(t.counts[buddy]) > 2: break
    let survivor = if buddyPrefix < prefix: buddy else: bucket
    let removed = if survivor == bucket: buddy else: bucket
    let keepCount = int(t.counts[survivor]); let dropCount = int(t.counts[removed])
    for j in 0 ..< dropCount: t.keys[survivor][keepCount + j] = t.keys[removed][j]
    t.counts[survivor] += t.counts[removed]; t.counts[removed] = 0
    t.keys[removed] = [0'u8, 0'u8]; t.depths[survivor] = uint8(d - 1); t.active[removed] = false
    for i in 0 ..< size:
      if int(t.directory[i]) == removed: t.directory[i] = uint8(survivor)
    dec t.buckets; bucket = survivor
  while t.gd > 1:
    let half = 1 shl (t.gd - 1)
    var mirror = true
    for i in 0 ..< half:
      if t.directory[i] != t.directory[i + half]: mirror = false; break
    if not mirror: break
    dec t.gd

proc extendible_hashing_trace*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "extendible_hashing_trace".} =
  if input.isNil or length < 1 or length > csize_t(MaxWords): return -1
  let qv = input[0]
  if qv < 0 or qv > MaxOps or length != csize_t(1 + 2 * qv): return -1
  let q = int(qv)
  for i in 0 ..< q:
    if input[1 + 2*i] < 0 or input[1 + 2*i] > 2 or input[2 + 2*i] < 0 or input[2 + 2*i] > 255: return -1
  var t = initTable()
  var successes = 0'u64
  for i in 0 ..< q:
    let op = int(input[1 + 2*i]); let key = int(input[2 + 2*i])
    var bucket = bucketFor(t, key); let slot = findSlot(t, bucket, key)
    var success = 0'u64
    if op == 0 and slot < 0:
      while t.counts[bucket] == 2:
        if not split(t, bucket): break
        bucket = bucketFor(t, key)
      if t.counts[bucket] < 2:
        t.keys[bucket][int(t.counts[bucket])] = uint8(key); inc t.counts[bucket]; inc t.live; success = 1
    elif op == 1 and slot >= 0:
      dec t.counts[bucket]
      t.keys[bucket][slot] = t.keys[bucket][int(t.counts[bucket])]
      t.keys[bucket][int(t.counts[bucket])] = 0
      dec t.live; success = 1; coalesce(t, bucket)
    elif op == 2: success = if slot >= 0: 1'u64 else: 0'u64
    successes = (successes shl 1) or success
  int64(successes or (uint64(t.buckets) shl 40) or (uint64(t.gd) shl 49) or
        (uint64(t.highDepth) shl 53) or (uint64(t.live) shl 57))
