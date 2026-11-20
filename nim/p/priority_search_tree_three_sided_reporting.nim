# Clean-room McCreight radix priority-search-tree profile.
const MaxN = 8
const MaxQ = 7
const XDomain = 32
const MaxInput = 48

proc priority_search_tree_three_sided_reporting*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "priority_search_tree_three_sided_reporting".} =
  if input.isNil or length < csize_t(2) or length > csize_t(MaxInput): return -1
  let n64 = input[0]
  let q64 = input[1]
  if n64 < 0 or n64 > MaxN.int64 or q64 < 0 or q64 > MaxQ.int64: return -1
  let n = int(n64)
  let q = int(q64)
  if int64(length) != 2 + 3 * n64 + 3 * q64: return -1
  var nx, ny, nl, nlo, nhi: array[MaxN, int64]
  var left, right: array[MaxN, int]
  var seenX: array[XDomain, bool]
  var seenLabel: array[MaxN, bool]
  for i in 0 ..< MaxN: left[i] = -1; right[i] = -1
  var root = -1
  var count = 0
  var at = 2
  for _ in 0 ..< n:
    let x = input[at]; let y = input[at + 1]; let label = input[at + 2]
    at += 3
    if x < 0 or x >= XDomain.int64 or y < -64 or y > 63 or label < 0 or label >= MaxN.int64: return -1
    if seenX[int(x)] or seenLabel[int(label)]: return -1
    seenX[int(x)] = true; seenLabel[int(label)] = true
    var px = x; var py = y; var pl = label
    if root < 0:
      root = count; inc count
      nx[root] = px; ny[root] = py; nl[root] = pl; nlo[root] = 0; nhi[root] = XDomain
    else:
      var current = root
      var low = 0
      var high = XDomain
      var searching = true
      while searching:
        if py < ny[current]:
          swap(px, nx[current]); swap(py, ny[current]); swap(pl, nl[current])
        let middle = (low + high) div 2
        if px < middle.int64:
          if left[current] < 0:
            let child = count; inc count; left[current] = child
            nx[child] = px; ny[child] = py; nl[child] = pl
            nlo[child] = low; nhi[child] = middle
            searching = false
          else:
            current = left[current]; high = middle
        else:
          if right[current] < 0:
            let child = count; inc count; right[current] = child
            nx[child] = px; ny[child] = py; nl[child] = pl
            nlo[child] = middle; nhi[child] = high
            searching = false
          else:
            current = right[current]; low = middle
  var qx0, qx1, qy1: array[MaxQ, int64]
  for i in 0 ..< q:
    qx0[i] = input[at]; qx1[i] = input[at + 1]; qy1[i] = input[at + 2]; at += 3
    if qx0[i] < 0 or qx0[i] > qx1[i] or qx1[i] >= XDomain.int64 or qy1[i] < -64 or qy1[i] > 63: return -1
  var result = 0'i64
  for qi in 0 ..< q:
    var mask = 0'i64
    if root >= 0:
      var stack: array[MaxN, int]
      var top = 1
      stack[0] = root
      while top > 0:
        dec top
        let node = stack[top]
        if qx1[qi] < nlo[node] or qx0[qi] >= nhi[node] or ny[node] > qy1[qi]: continue
        if qx0[qi] <= nx[node] and nx[node] <= qx1[qi]: mask = mask or (1'i64 shl int(nl[node]))
        if left[node] >= 0: stack[top] = left[node]; inc top
        if right[node] >= 0: stack[top] = right[node]; inc top
    result = result or (mask shl (8 * qi))
  result
