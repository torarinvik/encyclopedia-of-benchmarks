type Summary = tuple[value: int64, balance: int]

proc combine(a, b: Summary): Summary =
  if a.balance == 0: return b
  if b.balance == 0: return a
  if a.value == b.value: return (a.value, a.balance+b.balance)
  if a.balance >= b.balance: return (a.value, a.balance-b.balance)
  (b.value, b.balance-a.balance)

proc slot(value: int64, names: var array[128, int64], size: var int): int =
  for i in 0 ..< size:
    if names[i] == value: return i
  result = size
  names[size] = value
  inc size

proc prefixMask(pos: int): uint64 =
  if pos == 64: return high(uint64)
  (1'u64 shl pos)-1

proc dynamic_range_majority*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc.} =
  if input == nil or length < 2 or length > 258: return -1
  if input[0] < 1 or input[0] > 64 or input[1] < 1 or input[1] > 64: return -1
  let n = int(input[0]); let q = int(input[1])
  if int(length) != 2+n+3*q: return -1
  for i in 0 ..< n:
    if input[2+i] < 0 or input[2+i] > 1000000000: return -1
  var queries = 0
  for i in 0 ..< q:
    let b = 2+n+3*i
    if input[b] == 0:
      if input[b+1] < 0 or input[b+1] >= int64(n) or input[b+2] < 0 or input[b+2] > 1000000000: return -1
    elif input[b] == 1:
      if input[b+1] < 0 or input[b+1] >= input[b+2] or input[b+2] > int64(n): return -1
      inc queries
    else: return -1
  if queries == 0: return -1
  if output == nil or capacity < csize_t(8*queries): return -2
  var tree: array[128, Summary]
  var names, data: array[128, int64]
  var masks: array[128, uint64]
  var distinct = 0
  for i in 0 ..< n:
    data[i] = input[2+i]; tree[64+i] = (data[i],1)
    let s = slot(data[i],names,distinct)
    masks[s] = masks[s] or (1'u64 shl i)
  for i in countdown(63, 1): tree[i] = combine(tree[2*i],tree[2*i+1])
  var written = 0
  for i in 0 ..< q:
    let b = 2+n+3*i
    if input[b] == 0:
      let p = int(input[b+1]); let value = input[b+2]
      let old = slot(data[p],names,distinct); let fresh = slot(value,names,distinct)
      masks[old] = masks[old] and not (1'u64 shl p)
      masks[fresh] = masks[fresh] or (1'u64 shl p)
      data[p] = value
      var node = 64+p; tree[node] = (value,1)
      while node > 1:
        node = node div 2
        tree[node] = combine(tree[2*node],tree[2*node+1])
    else:
      let lo = int(input[b+1]); let hi = int(input[b+2])
      var l = lo+64; var r = hi+64
      var a, c: Summary
      while l < r:
        if (l and 1) != 0: a = combine(a,tree[l]); inc l
        if (r and 1) != 0: dec r; c = combine(tree[r],c)
        l = l div 2; r = r div 2
      let candidate = combine(a,c)
      var answer: int64 = -1
      if candidate.balance > 0:
        let s = slot(candidate.value,names,distinct)
        var bits = masks[s] and (prefixMask(hi) xor prefixMask(lo))
        var count = 0
        while bits != 0: bits = bits and (bits-1); inc count
        if 2*count > hi-lo: answer = candidate.value
      let encoded = cast[uint64](answer)
      for byte in 0 ..< 8: output[8*written+byte] = uint8((encoded shr (8*byte)) and 255)
      inc written
  return int64(8*written)
