const MaxN = 8
const MaxM = 28
const MaxInput = 90

proc bswBefore(aw, au, av, bw, bu, bv: int64): bool =
  aw < bw or (aw == bw and au < bu) or (aw == bw and au == bu and av < bv)

proc baswana_sen_weighted_spanner*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "baswana_sen_weighted_spanner".} =
  if input.isNil or length < csize_t(3) or length > csize_t(MaxInput): return -1
  let n64 = input[0]
  let m64 = input[1]
  let k = input[2]
  if n64 < 2 or n64 > int64(MaxN) or m64 < 0 or m64 > int64(MaxM) or k < 2 or k > 3: return -1
  let n = int(n64)
  let m = int(m64)
  let rounds = int(k - 1)
  if int64(length) != 3 + rounds + 3 * m: return -1
  var masks: array[MaxN, int64]
  for r in 0 ..< rounds:
    masks[r] = input[3 + r]
    if masks[r] < 0 or masks[r] >= (1'i64 shl n): return -1
  var edgeU, edgeV, edgeW: array[MaxM, int64]
  var active, selected: array[MaxM, bool]
  let offset = 3 + rounds
  for e in 0 ..< m:
    edgeU[e] = input[offset + 3 * e]
    edgeV[e] = input[offset + 3 * e + 1]
    edgeW[e] = input[offset + 3 * e + 2]
    if edgeU[e] < 0 or edgeV[e] <= edgeU[e] or edgeV[e] >= n64 or edgeW[e] < 1 or edgeW[e] > 32: return -1
    for p in 0 ..< e:
      if edgeU[p] == edgeU[e] and edgeV[p] == edgeV[e]: return -1
    active[e] = true
  if output.isNil or capacity < csize_t(m): return -2

  var cluster, nextCluster: array[MaxN, int]
  for v in 0 ..< n: cluster[v] = v
  for r in 0 ..< rounds:
    var sampled: array[MaxN, bool]
    var remove: array[MaxM, bool]
    var groupBest: array[MaxN * MaxN, int]
    for i in 0 ..< MaxN * MaxN: groupBest[i] = m
    for v in 0 ..< n: nextCluster[v] = -1
    for v in 0 ..< n:
      let center = cluster[v]
      if center >= 0 and ((masks[r] shr center) and 1) != 0: sampled[center] = true
    for v in 0 ..< n:
      if cluster[v] >= 0 and sampled[cluster[v]]: nextCluster[v] = cluster[v]
    for e in 0 ..< m:
      if not active[e]: continue
      let u = int(edgeU[e])
      let v = int(edgeV[e])
      if cluster[v] >= 0:
        let slot = u * MaxN + cluster[v]
        let prior = groupBest[slot]
        if prior == m or bswBefore(edgeW[e], edgeU[e], edgeV[e], edgeW[prior], edgeU[prior], edgeV[prior]): groupBest[slot] = e
      if cluster[u] >= 0:
        let slot = v * MaxN + cluster[u]
        let prior = groupBest[slot]
        if prior == m or bswBefore(edgeW[e], edgeU[e], edgeV[e], edgeW[prior], edgeU[prior], edgeV[prior]): groupBest[slot] = e
    for v in 0 ..< n:
      let old = cluster[v]
      if old < 0 or sampled[old]: continue
      var best = m
      for c in 0 ..< n:
        let candidate = groupBest[v * MaxN + c]
        if sampled[c] and candidate != m and (best == m or bswBefore(edgeW[candidate], edgeU[candidate], edgeV[candidate], edgeW[best], edgeU[best], edgeV[best])): best = candidate
      if best == m:
        for c in 0 ..< n:
          let least = groupBest[v * MaxN + c]
          if least == m: continue
          selected[least] = true
          for e in 0 ..< m:
            if not active[e]: continue
            let a = int(edgeU[e])
            let b = int(edgeV[e])
            if (a == v and cluster[b] == c) or (b == v and cluster[a] == c): remove[e] = true
      else:
        let a = int(edgeU[best])
        let b = int(edgeV[best])
        let landing = cluster[if a == v: b else: a]
        nextCluster[v] = landing
        selected[best] = true
        for c in 0 ..< n:
          let least = groupBest[v * MaxN + c]
          if least == m: continue
          let eraseGroup = c == landing or edgeW[least] < edgeW[best]
          if c != landing and edgeW[least] < edgeW[best]: selected[least] = true
          if eraseGroup:
            for e in 0 ..< m:
              if not active[e]: continue
              let x = int(edgeU[e])
              let y = int(edgeV[e])
              if (x == v and cluster[y] == c) or (y == v and cluster[x] == c): remove[e] = true
    for e in 0 ..< m:
      if remove[e]: active[e] = false
    for e in 0 ..< m:
      if active[e]:
        let u = int(edgeU[e])
        let v = int(edgeV[e])
        if nextCluster[u] >= 0 and nextCluster[u] == nextCluster[v]: active[e] = false
    cluster = nextCluster

  var groupBest: array[MaxN * MaxN, int]
  for i in 0 ..< MaxN * MaxN: groupBest[i] = m
  for e in 0 ..< m:
    if not active[e]: continue
    let u = int(edgeU[e])
    let v = int(edgeV[e])
    if cluster[v] >= 0:
      let slot = u * MaxN + cluster[v]
      let prior = groupBest[slot]
      if prior == m or bswBefore(edgeW[e], edgeU[e], edgeV[e], edgeW[prior], edgeU[prior], edgeV[prior]): groupBest[slot] = e
    if cluster[u] >= 0:
      let slot = v * MaxN + cluster[u]
      let prior = groupBest[slot]
      if prior == m or bswBefore(edgeW[e], edgeU[e], edgeV[e], edgeW[prior], edgeU[prior], edgeV[prior]): groupBest[slot] = e
  for v in 0 ..< n:
    if cluster[v] >= 0:
      for c in 0 ..< n:
        let least = groupBest[v * MaxN + c]
        if least != m: selected[least] = true
  for e in 0 ..< m: output[e] = uint8(ord(selected[e]))
  int64(m)
