const
  Mod = 998244353'i64
  NMax = 16
  QMax = 32
  Base = 16
  InputMax = 5 * NMax + 4 * QMax - 2
  Pair = tuple[m, a: int64]

proc compose(left, right: Pair): Pair =
  (left.m * right.m mod Mod, (left.m * right.a + left.a) mod Mod)

proc findRoot(parent: var array[NMax, int], x0: int): int =
  var x = x0
  while parent[x] != x:
    parent[x] = parent[parent[x]]
    x = parent[x]
  x

proc setLeaf(seg: var array[2 * Base, Pair], pos: array[NMax, int],
             mul, add: array[NMax, int64], u: int) =
  var k = Base + pos[u]
  seg[k] = (mul[u], add[u])
  k = k div 2
  while k > 0:
    seg[k] = compose(seg[2*k], seg[2*k+1])
    k = k div 2

proc chainValue(seg: array[2 * Base, Pair], pos, ends: array[NMax, int], h: int): int64 =
  var l = Base + pos[h]
  var r = Base + ends[h]
  var left: Pair = (1, 0)
  var right: Pair = (1, 0)
  while l < r:
    if (l and 1) != 0:
      left = compose(left, seg[l])
      inc l
    if (r and 1) != 0:
      dec r
      right = compose(seg[r], right)
    l = l div 2
    r = r div 2
  compose(left, right).a

proc storeLe(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[offset + byte] = uint8((bits shr (8 * byte)) and 255'u64)

proc point_set_tree_path_composite_sum_fixed_root*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl,
    exportc: "point_set_tree_path_composite_sum_fixed_root".} =
  if input.isNil or length < 2 or length > csize_t(InputMax): return -1
  let nr = input[0]
  let qr = input[1]
  if nr < 1 or nr > NMax.int64 or qr < 1 or qr > QMax.int64: return -1
  let n = int(nr)
  let q = int(qr)
  var cursor = 2
  var value: array[NMax, int64]
  for u in 0 ..< n:
    if cursor >= int(length): return -1
    value[u] = input[cursor]
    inc cursor
    if value[u] < 0 or value[u] >= Mod: return -1

  var edgeAt: array[NMax, array[NMax, int]]
  for u in 0 ..< NMax:
    for v in 0 ..< NMax: edgeAt[u][v] = -1
  var eu, ev: array[NMax - 1, int]
  var eb, ec: array[NMax - 1, int64]
  var dsu, dsz: array[NMax, int]
  for u in 0 ..< n: (dsu[u], dsz[u]) = (u, 1)
  for e in 0 ..< n - 1:
    if cursor + 4 > int(length): return -1
    let ur = input[cursor]; let vr = input[cursor+1]
    let b = input[cursor+2]; let c = input[cursor+3]
    cursor += 4
    if ur < 0 or ur >= nr or vr < 0 or vr >= nr or ur == vr or b < 1 or b >= Mod or c < 0 or c >= Mod: return -1
    let u = int(ur); let v = int(vr)
    var ru = findRoot(dsu, u); var rv = findRoot(dsu, v)
    if ru == rv: return -1
    if dsz[ru] < dsz[rv]: swap(ru, rv)
    dsu[rv] = ru; dsz[ru] += dsz[rv]
    eu[e] = u; ev[e] = v; eb[e] = b; ec[e] = c
    edgeAt[u][v] = e; edgeAt[v][u] = e

  var kind, ox, oy, oz: array[QMax, int64]
  for i in 0 ..< q:
    if cursor >= int(length): return -1
    kind[i] = input[cursor]; inc cursor
    if kind[i] == 0:
      if cursor + 2 > int(length): return -1
      ox[i] = input[cursor]; oy[i] = input[cursor+1]; cursor += 2
      if ox[i] < 0 or ox[i] >= nr or oy[i] < 0 or oy[i] >= Mod: return -1
    elif kind[i] == 1:
      if cursor + 3 > int(length): return -1
      ox[i] = input[cursor]; oy[i] = input[cursor+1]; oz[i] = input[cursor+2]; cursor += 3
      if ox[i] < 0 or ox[i] >= nr-1 or oy[i] < 1 or oy[i] >= Mod or oz[i] < 0 or oz[i] >= Mod: return -1
    else: return -1
  if cursor != int(length): return -1
  let bytes = 8 * q
  if output.isNil or capacity < csize_t(bytes): return -2

  var parent: array[NMax, int]
  var pedge: array[NMax, int]
  var order, stack: array[NMax, int]
  var count = 0; var top = 1
  for u in 0 ..< n: (parent[u], pedge[u]) = (-2, -1)
  parent[0] = -1; stack[0] = 0
  while top > 0:
    dec top
    let u = stack[top]
    order[count] = u; inc count
    for v in 0 ..< n:
      if edgeAt[u][v] >= 0 and v != parent[u]:
        parent[v] = u; pedge[v] = edgeAt[u][v]; stack[top] = v; inc top

  var sub: array[NMax, int]
  var heavy: array[NMax, int]
  for u in 0 ..< n: (sub[u], heavy[u]) = (1, -1)
  for ii in countdown(count - 1, 0):
    let u = order[ii]
    var best = 0
    for v in 0 ..< n:
      if parent[v] == u:
        sub[u] += sub[v]
        if sub[v] > best or (sub[v] == best and (heavy[u] < 0 or v < heavy[u])):
          best = sub[v]; heavy[u] = v
  var head, pos, ends, chainHeads: array[NMax, int]
  var timer = 0; top = 1; chainHeads[0] = 0
  while top > 0:
    dec top
    let h = chainHeads[top]
    var u = h
    while true:
      head[u] = h; pos[u] = timer; inc timer
      for v in 0 ..< n:
        if parent[v] == u and v != heavy[u]: chainHeads[top] = v; inc top
      if heavy[u] < 0: break
      u = heavy[u]
    ends[h] = timer

  var down: array[NMax, int64]
  for ii in countdown(count - 1, 0):
    let u = order[ii]
    down[u] = value[u]
    for v in 0 ..< n:
      if parent[v] == u:
        let e = pedge[v]
        down[u] += eb[e] * down[v] + ec[e] * int64(sub[v])
    down[u] = down[u] mod Mod
  var mul, add: array[NMax, int64]
  for u in 0 ..< n:
    add[u] = value[u]
    for v in 0 ..< n:
      if parent[v] == u:
        let e = pedge[v]
        if heavy[u] == v:
          mul[u] = eb[e]; add[u] += ec[e] * int64(sub[v])
        else: add[u] += eb[e] * down[v] + ec[e] * int64(sub[v])
    add[u] = add[u] mod Mod
  var seg: array[2 * Base, Pair]
  for i in 0 ..< 2 * Base: seg[i] = (1, 0)
  for u in 0 ..< n: seg[Base+pos[u]] = (mul[u], add[u])
  for i in countdown(Base-1, 1): seg[i] = compose(seg[2*i], seg[2*i+1])
  var current: array[NMax, int64]
  for u in 0 ..< n:
    if head[u] == u: current[u] = down[u]

  for qi in 0 ..< q:
    var start: int
    if kind[qi] == 0:
      let u = int(ox[qi])
      add[u] = (add[u] + oy[qi] - value[u]) mod Mod
      if add[u] < 0: add[u] += Mod
      value[u] = oy[qi]; setLeaf(seg, pos, mul, add, u); start = u
    else:
      let e = int(ox[qi]); let u = eu[e]; let v = ev[e]
      let child = if parent[u] == v: u else: v
      let p = parent[child]; let ob = eb[e]; let oc = ec[e]
      if heavy[p] == child:
        mul[p] = oy[qi]
        add[p] = (add[p] + (oz[qi] - oc) * int64(sub[child])) mod Mod
      else:
        add[p] = (add[p] + (oy[qi] - ob) * current[child] + (oz[qi] - oc) * int64(sub[child])) mod Mod
      if add[p] < 0: add[p] += Mod
      eb[e] = oy[qi]; ec[e] = oz[qi]; setLeaf(seg, pos, mul, add, p); start = p
    var u = start
    while true:
      let h = head[u]; let old = current[h]
      current[h] = chainValue(seg, pos, ends, h)
      if h == 0: break
      let p = parent[h]; let e = pedge[h]
      add[p] = (add[p] + eb[e] * (current[h] - old)) mod Mod
      if add[p] < 0: add[p] += Mod
      setLeaf(seg, pos, mul, add, p); u = p
    storeLe(output, 8 * qi, current[0])
  int64(bytes)
