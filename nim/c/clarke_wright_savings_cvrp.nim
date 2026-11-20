proc reverseRoute(routes: var array[49, int], slot, length: int) =
  var left = 0
  var right = length - 1
  while left < right:
    swap(routes[slot * 7 + left], routes[slot * 7 + right])
    inc left
    dec right

proc compareRoutes(a: array[49, int], aSlot, aLength: int,
                   b: array[49, int], bSlot, bLength: int): int =
  let shared = min(aLength, bLength)
  for i in 0..<shared:
    if a[aSlot * 7 + i] < b[bSlot * 7 + i]: return -1
    if a[aSlot * 7 + i] > b[bSlot * 7 + i]: return 1
  if aLength < bLength: return -1
  if aLength > bLength: return 1
  0

proc putI64(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for i in 0..<8: output[offset + i] = uint8((bits shr (8 * i)) and 255)

proc clarke_wright_savings_cvrp*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc:"clarke_wright_savings_cvrp".} =
  if input.isNil or length < 2 or length > 74: return -1
  let n0 = input[0]
  let cap0 = input[1]
  if n0 < 0 or n0 > 7 or cap0 < 1 or cap0 > 100: return -1
  let n = int(n0)
  let vehicleCapacity = int(cap0)
  let width = n + 1
  if int(length) != 2 + n + width * width: return -1

  var demand: array[8, int64]
  for customerOffset in 0..<n:
    let customer = customerOffset + 1
    demand[customer] = input[1 + customer]
    if demand[customer] < 1 or demand[customer] > cap0: return -1
  var distance: array[64, int64]
  let offset = 2 + n
  for i in 0..<width:
    for j in 0..<width:
      let d = input[offset + i * width + j]
      if d < 0 or d > 1000 or (i == j and d != 0): return -1
      distance[i * 8 + j] = d
  for i in 0..<width:
    for j in i + 1..<width:
      if distance[i * 8 + j] != distance[j * 8 + i]: return -1

  var routes: array[49, int]
  var routeLength: array[7, int]
  var load: array[7, int64]
  var active: array[7, bool]
  for r in 0..<n:
    routes[r * 7] = r + 1
    routeLength[r] = 1
    load[r] = demand[r + 1]
    active[r] = true

  var savings: array[21, int64]
  var pairI, pairJ: array[21, int]
  var pairCount = 0
  for i in 1..<n + 1:
    for j in i + 1..<n + 1:
      savings[pairCount] = distance[i] + distance[j] - distance[i * 8 + j]
      pairI[pairCount] = i
      pairJ[pairCount] = j
      inc pairCount
  for i in 0..<pairCount:
    for j in i + 1..<pairCount:
      if (savings[j] > savings[i]
          or savings[j] == savings[i] and
             (pairI[j] < pairI[i] or pairI[j] == pairI[i] and pairJ[j] < pairJ[i])):
        swap(savings[i], savings[j])
        swap(pairI[i], pairI[j])
        swap(pairJ[i], pairJ[j])

  for p in 0..<pairCount:
    if savings[p] <= 0: break
    var ri = -1
    var rj = -1
    var pi = -1
    var pj = -1
    for r in 0..<n:
      if active[r]:
        for at in 0..<routeLength[r]:
          if routes[r * 7 + at] == pairI[p]:
            ri = r
            pi = at
          if routes[r * 7 + at] == pairJ[p]:
            rj = r
            pj = at
    if ri == rj or ri < 0 or rj < 0: continue
    if ((pi != 0 and pi != routeLength[ri] - 1)
        or (pj != 0 and pj != routeLength[rj] - 1)
        or load[ri] + load[rj] > vehicleCapacity): continue
    if pi == 0: reverseRoute(routes, ri, routeLength[ri])
    if pj == routeLength[rj] - 1: reverseRoute(routes, rj, routeLength[rj])
    let oldLength = routeLength[ri]
    for at in 0..<routeLength[rj]: routes[ri * 7 + oldLength + at] = routes[rj * 7 + at]
    routeLength[ri] += routeLength[rj]
    load[ri] += load[rj]
    active[rj] = false
    routeLength[rj] = 0
    load[rj] = 0

  var finalRoutes: array[49, int]
  var finalLength: array[7, int]
  var count = 0
  for r in 0..<n:
    if active[r]:
      var reverseFirst = false
      for at in 0..<routeLength[r]:
        let a = routes[r * 7 + at]
        let b = routes[r * 7 + routeLength[r] - 1 - at]
        if a != b: reverseFirst = a > b; break
      if reverseFirst: reverseRoute(routes, r, routeLength[r])
      for at in 0..<routeLength[r]: finalRoutes[count * 7 + at] = routes[r * 7 + at]
      finalLength[count] = routeLength[r]
      inc count
  for i in 0..<count:
    for j in i + 1..<count:
      if compareRoutes(finalRoutes, i, finalLength[i], finalRoutes, j, finalLength[j]) > 0:
        for k in 0..<7: swap(finalRoutes[i * 7 + k], finalRoutes[j * 7 + k])
        swap(finalLength[i], finalLength[j])

  var words: array[15, int64]
  var wordCount = 0
  words[wordCount] = int64(count); inc wordCount
  for r in 0..<count:
    words[wordCount] = int64(finalLength[r]); inc wordCount
    for at in 0..<finalLength[r]: words[wordCount] = int64(finalRoutes[r * 7 + at]); inc wordCount
  let bytes = wordCount * 8
  if output.isNil or int(capacity) < bytes: return -2
  for i in 0..<wordCount: putI64(output, i * 8, words[i])
  int64(bytes)
