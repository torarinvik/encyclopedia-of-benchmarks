proc hashValue(h0: uint64, value: int64): uint64 =
  var h = h0
  let bits = cast[uint64](value)
  for i in 0 .. 7:
    h = (h xor ((bits shr (8 * i)) and 255'u64)) * 0x100000001b3'u64
  h

proc generic_hash_map*(a: ptr UncheckedArray[int64], n: csize_t): int64 {.cdecl, exportc:"generic_hash_map".} =
  if a == nil or n < 1 or n > 385 or a[0] < 0 or a[0] > 128 or n != csize_t(1 + 3 * a[0]): return -1
  var keys: array[64, int64]
  var vals: array[64, int64]
  var nxt: array[64, int]
  var head: array[128, int]
  var active: array[64, bool]
  for i in 0 ..< 64: nxt[i] = -1
  for i in 0 ..< 128: head[i] = -1
  var size = 0
  var bucketCount = 16
  var h = 0xcbf29ce484222325'u64
  for oi in 0 ..< int(a[0]):
    let op = a[1 + 3 * oi]
    let key = a[2 + 3 * oi]
    let value = a[3 + 3 * oi]
    if key < 0 or key > 1000000: return -1
    var b = int(key mod bucketCount)
    var found = -1
    var j = head[b]
    while j >= 0:
      if keys[j] == key: found = j; break
      j = nxt[j]
    if op == 0:
      if value < -1000000 or value > 1000000: return -1
      if found >= 0: vals[found] = value
      else:
        if size >= 64: return -1
        var slot = 0
        while active[slot]: inc slot
        active[slot] = true; keys[slot] = key; vals[slot] = value; nxt[slot] = head[b]; head[b] = slot; inc size
        if size * 4 > bucketCount * 3 and bucketCount < 128:
          bucketCount *= 2
          for q in 0 ..< 128: head[q] = -1
          for q in 0 ..< 64:
            if active[q]:
              b = int(keys[q] mod bucketCount); nxt[q] = head[b]; head[b] = q
    elif op == 1 or op == 3:
      if value != 0: return -1
      let observed = if op == 1: (if found >= 0: vals[found] else: low(int64)) else: (if found >= 0: 1'i64 else: 0'i64)
      h = hashValue(h, observed)
    elif op == 2:
      if value != 0: return -1
      if found >= 0:
        var prev = -1
        j = head[b]
        while j >= 0:
          if j == found:
            if prev < 0: head[b] = nxt[j] else: nxt[prev] = nxt[j]
            break
          prev = j; j = nxt[j]
        active[found] = false; dec size
    elif op == 4:
      if key != 0 or value != 0: return -1
      h = hashValue(h, int64(size))
    else: return -1
  h = hashValue(h, int64(size))
  var used: array[64, bool]
  for rank in 0 ..< size:
    var best = -1
    for i in 0 ..< 64:
      if active[i] and not used[i] and (best < 0 or keys[i] < keys[best]): best = i
    used[best] = true; h = hashValue(hashValue(h, keys[best]), vals[best])
  cast[int64](h)
