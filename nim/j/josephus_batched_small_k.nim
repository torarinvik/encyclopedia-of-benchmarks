proc josephus_batched_small_k*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "josephus_batched_small_k".} =
  if values == nil or length != 2: return -1
  let n0 = values[0]
  let k = values[1]
  if n0 < 1 or n0 > 1_000_000 or k < 1 or k > 32: return -1
  if n0 == 1: return 0
  if k == 1: return n0 - 1
  var frames: array[1024, int64]
  var depth = 0
  var n = n0
  while n > 1:
    if depth == frames.len: return -1
    frames[depth] = n
    inc depth
    if n < k: dec n
    else: n -= n div k
  var survivor = 0'i64
  while depth > 0:
    dec depth
    let m = frames[depth]
    if m < k: survivor = (survivor + k) mod m
    else:
      survivor -= m mod k
      if survivor < 0: survivor += m
      else: survivor += survivor div (k - 1)
  survivor
