const MaxN = 8
const MaxM = 28
const MaxInput = 59
const Inf = 9

proc put(outp: ptr UncheckedArray[uint8], at: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0..<8: outp[at + byte] = uint8((bits shr (8 * byte)) and 255)

proc distances(n, m: int, u, v: array[MaxM, int], selected: array[MaxM, bool],
               onlySelected: bool): array[MaxN * MaxN, int] =
  var d: array[MaxN * MaxN, int]
  for left in 0..<n:
    for right in 0..<n: d[left * MaxN + right] = if left == right: 0 else: Inf
  for edge in 0..<m:
    if onlySelected and not selected[edge]: continue
    d[u[edge] * MaxN + v[edge]] = 1
    d[v[edge] * MaxN + u[edge]] = 1
  for via in 0..<n:
    for left in 0..<n:
      for right in 0..<n:
        let candidate = d[left * MaxN + via] + d[via * MaxN + right]
        if candidate < d[left * MaxN + right]: d[left * MaxN + right] = candidate
  d

proc additive_two_spanner_completion*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc:"additive_two_spanner_completion".} =
  if input.isNil or length < 2 or length > csize_t(MaxInput): return -1
  let n0 = input[0]
  let m0 = input[1]
  if n0 < 1 or n0 > 8 or m0 < 0 or m0 > 28: return -1
  let n = int(n0)
  let m = int(m0)
  if int(length) != 2 + 2 * m: return -1
  var u, v: array[MaxM, int]
  for edge in 0..<m:
    let a = input[2 + 2 * edge]
    let b = input[3 + 2 * edge]
    if a < 0 or a >= b or b >= n0: return -1
    u[edge] = int(a)
    v[edge] = int(b)
    for prior in 0..<edge:
      if u[prior] == u[edge] and v[prior] == v[edge]: return -1
  var selected: array[MaxM, bool]
  let original = distances(n, m, u, v, selected, false)
  for round in 0..m:
    let current = distances(n, m, u, v, selected, true)
    var source = n
    var target = n
    block pairs:
      for a in 0..<n:
        for b in (a + 1)..<n:
          if original[a * MaxN + b] < Inf and current[a * MaxN + b] > original[a * MaxN + b] + 2:
            source = a
            target = b
            break pairs
    if source == n: break
    if round == m: return -1
    var vertex = source
    while vertex != target:
      var next = n
      for neighbor in 0..<n:
        if neighbor == vertex or original[neighbor * MaxN + target] + 1 != original[vertex * MaxN + target]: continue
        for edge in 0..<m:
          if (u[edge] == vertex and v[edge] == neighbor) or (v[edge] == vertex and u[edge] == neighbor):
            next = neighbor
            selected[edge] = true
            break
        if next != n: break
      if next == n: return -1
      vertex = next
  var count = 0
  for edge in 0..<m:
    if selected[edge]: inc count
  let bytes = 8 * (1 + 2 * count)
  if output.isNil or int(capacity) < bytes: return -2
  put(output, 0, int64(count))
  var slot = 0
  for edge in 0..<m:
    if not selected[edge]: continue
    put(output, 8 * (1 + 2 * slot), int64(u[edge]))
    put(output, 8 * (2 + 2 * slot), int64(v[edge]))
    inc slot
  int64(bytes)
