const MaxN = 3
const MaxM = 3
const MaxCuts = 45

proc putI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  var bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8(bits and 255'u64)
    bits = bits shr 8

proc popCount(value: uint64): int =
  var bits = value
  var count = 0
  while bits != 0'u64:
    bits = bits and (bits - 1'u64)
    inc count
  count

proc shiftCut(cut: uint64, n, delay: int, result: var uint64): bool =
  result = 0'u64
  for bit in 0 ..< 3*n:
    if (cut and (1'u64 shl bit)) != 0'u64:
      let node = bit div 3
      let nextDelay = bit mod 3 + delay
      if nextDelay > 2: return false
      result = result or (1'u64 shl (3*node + nextDelay))
  true

proc addCut(cuts: var array[MaxN, array[MaxCuts, uint64]], counts: var array[MaxN, int],
            node: int, mask: uint64, k: int) =
  if popCount(mask) > k: return
  for i in 0 ..< counts[node]:
    if cuts[node][i] == mask: return
  if counts[node] < MaxCuts:
    cuts[node][counts[node]] = mask
    inc counts[node]

proc sequential_lut_k_cut_enumeration*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "sequential_lut_k_cut_enumeration".} =
  if input == nil or length < 3 or length > 12: return -1
  let n0=input[0]; let k0=input[1]; let m0=input[2]
  if n0 < 1 or n0 > 3 or k0 < 1 or k0 > 2 or m0 < 0 or m0 > 3 or length != csize_t(3+3*m0): return -1
  let n=int(n0); let k=int(k0); let m=int(m0)
  var edgeU, edgeV, edgeD: array[MaxM, int]
  for e in 0 ..< m:
    let u=input[3+3*e]; let v=input[4+3*e]; let d=input[5+3*e]
    if u < 0 or v <= u or v >= n0 or (d != 0 and d != 1): return -1
    for j in 0 ..< e:
      if edgeU[j] == int(u) and edgeV[j] == int(v) and edgeD[j] == int(d): return -1
    edgeU[e]=int(u); edgeV[e]=int(v); edgeD[e]=int(d)
  var incomingU: array[MaxN, array[MaxM, int]]
  var incomingD: array[MaxN, array[MaxM, int]]
  var degree: array[MaxN, int]
  for e in 0 ..< m:
    let v=edgeV[e]; incomingU[v][degree[v]]=edgeU[e]; incomingD[v][degree[v]]=edgeD[e]; inc degree[v]
  var cuts: array[MaxN, array[MaxCuts, uint64]]
  var counts: array[MaxN, int]
  for v in 0 ..< n:
    addCut(cuts,counts,v,1'u64 shl (3*v),k)
    if degree[v] > 0:
      let c0=counts[incomingU[v][0]]
      let c1=if degree[v]>1: counts[incomingU[v][1]] else: 1
      let c2=if degree[v]>2: counts[incomingU[v][2]] else: 1
      for a in 0 ..< c0:
        for b in 0 ..< c1:
          for c in 0 ..< c2:
            var merged=0'u64
            var shifted: uint64
            if not shiftCut(cuts[incomingU[v][0]][a],n,incomingD[v][0],shifted): return -1
            merged = merged or shifted
            if degree[v] > 1:
              if not shiftCut(cuts[incomingU[v][1]][b],n,incomingD[v][1],shifted): return -1
              merged = merged or shifted
            if degree[v] > 2:
              if not shiftCut(cuts[incomingU[v][2]][c],n,incomingD[v][2],shifted): return -1
              merged = merged or shifted
            addCut(cuts,counts,v,merged,k)
    for i in 1 ..< counts[v]:
      let x=cuts[v][i]
      var j=i
      while j>0 and cuts[v][j-1]>x:
        cuts[v][j]=cuts[v][j-1]; dec j
      cuts[v][j]=x
  var words=1
  for v in 0 ..< n: words += 1+counts[v]
  let bytes=words*8
  if output == nil or capacity < csize_t(bytes): return -2
  putI64Le(output,0,int64(n)); var at=1
  for v in 0 ..< n:
    putI64Le(output,at,int64(counts[v])); inc at
    for i in 0 ..< counts[v]: putI64Le(output,at,int64(cuts[v][i])); inc at
  int64(bytes)
