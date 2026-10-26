# Clean-room high-/low-degree vertex-cover reduction profile.
const MaxN = 16
const MaxM = 64
const MaxInput = 131
const MaxFields = 133

proc putI64(outp: ptr UncheckedArray[uint8], at: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0..<8: outp[at+byte] = uint8((bits shr (8*byte)) and 255)

proc vertex_cover_kernelization*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "vertex_cover_kernelization".} =
  if input.isNil or length < csize_t(3) or length > csize_t(MaxInput): return -1
  let n64 = input[0]
  let m64 = input[1]
  var k = input[2]
  if n64 < 1 or n64 > 16 or m64 < 0 or m64 > 64 or k < 0 or k > 16 or int(length) != 3+2*int(m64): return -1
  let n = int(n64)
  let m = int(m64)
  var edge: array[MaxN*MaxN,bool]
  var previousU,previousV = -1'i64
  for e in 0..<m:
    let u = input[3+2*e]
    let v = input[4+2*e]
    if u < 0 or v <= u or v >= n64 or u < previousU or (u == previousU and v <= previousV): return -1
    edge[int(u)*MaxN+int(v)] = true; edge[int(v)*MaxN+int(u)] = true
    previousU=u; previousV=v
  if output.isNil: return -2
  var active: array[MaxN,bool]
  for i in 0..<n: active[i]=true
  var forced:uint64=0
  var infeasible=false
  while true:
    if k < 0: infeasible=true; break
    var chosen=n; var neighbor=n; var kind=0
    for u in 0..<n:
      if active[u]:
        var degree=0
        for v in 0..<n: if edge[u*MaxN+v]: inc degree
        if degree == 0: chosen=u; kind=1; break
    if kind == 1: active[chosen]=false; continue
    for u in 0..<n:
      if active[u]:
        var degree=0; var only=n
        for v in 0..<n:
          if edge[u*MaxN+v]:
            inc degree
            only=v
        if degree == 1: chosen=u; neighbor=only; kind=2; break
    if kind == 0:
      for u in 0..<n:
        if active[u]:
          var degree=0
          for v in 0..<n: if edge[u*MaxN+v]: inc degree
          if int64(degree)>k: chosen=u; kind=3; break
    if kind == 0: break
    let f=if kind == 2: neighbor else: chosen
    forced = forced or (1'u64 shl f)
    active[f]=false; dec k
    for v in 0..<n: edge[f*MaxN+v]=false; edge[v*MaxN+f]=false
  var staged: array[MaxFields,int64]
  var count=0
  staged[count]=if infeasible: 0 else: 1; inc count
  staged[count]=k; inc count
  staged[count]=cast[int64](forced); inc count
  var activeMask:uint64=0
  for v in 0..<n: if active[v]: activeMask=activeMask or (1'u64 shl v)
  staged[count]=cast[int64](activeMask); inc count
  var remaining=0
  for u in 0..<n: for v in u+1..<n: if edge[u*MaxN+v]: inc remaining
  staged[count]=int64(remaining); inc count
  for u in 0..<n:
    for v in u+1..<n:
      if edge[u*MaxN+v]: staged[count]=int64(u); staged[count+1]=int64(v); count+=2
  if capacity < csize_t(8*count): return -2
  for i in 0..<count: putI64(output,8*i,staged[i])
  int64(8*count)
