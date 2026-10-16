proc doubleHashHashTable*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "double_hash_hash_table".} =
  if length < 2: return -1
  let cap64 = input[0]
  let count64 = input[1]
  if cap64 < 3 or cap64 > 101 or count64 < 0 or count64 > 512: return -1
  let cap = int(cap64)
  if length != csize_t(2 + 2 * count64): return -1
  var divisor = 2
  while divisor * divisor <= cap:
    if cap mod divisor == 0: return -1
    inc divisor
  var states: array[101, uint8]
  var keys: array[101, int64]
  var successes = 0'i64
  for i in 0 ..< int(count64):
    let op = input[2 + 2 * i]
    let key = input[3 + 2 * i]
    if op < 1 or op > 3: return -1
    let first = int(((key mod cap64) + cap64) mod cap64)
    let step = 1 + int(((key mod (cap64 - 1)) + cap64 - 1) mod (cap64 - 1))
    if op == 1:
      var tomb = cap
      var inserted = false
      for p in 0 ..< cap:
        let slot = (first + p * step) mod cap
        if states[slot] == 1 and keys[slot] == key:
          tomb = cap
          break
        if states[slot] == 2 and tomb == cap: tomb = slot
        if states[slot] == 0:
          let target = if tomb == cap: slot else: tomb
          states[target] = 1
          keys[target] = key
          inserted = true
          break
      if not inserted and tomb != cap:
        states[tomb] = 1
        keys[tomb] = key
        inserted = true
      if inserted: inc successes
    else:
      for p in 0 ..< cap:
        let slot = (first + p * step) mod cap
        if states[slot] == 0: break
        if states[slot] == 1 and keys[slot] == key:
          inc successes
          if op == 3: states[slot] = 2
          break
  successes
