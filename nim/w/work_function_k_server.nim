# Clean-room bounded work-function algorithm for finite k-server metrics.
const MaxP = 6
const MaxK = 3
const MaxR = 8
const MaxConfigs = 20
const MaxInput = 50

proc storeI64LE(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0..<8: output[offset+byte] = uint8((bits shr (8*byte)) and 255)

proc sortCfg(x: var array[MaxK,int64], k: int) =
  for i in 0..<k:
    for j in i+1..<k:
      if x[j] < x[i]: swap(x[i],x[j])

proc findCfg(configs: array[MaxConfigs*MaxK,int64], count: int,
    x: array[MaxK,int64], k: int): int =
  for i in 0..<count:
    var same = true
    for j in 0..<k:
      if configs[i*MaxK+j] != x[j]: same = false
    if same: return i
  count

proc configDistance(a,b: array[MaxK,int64], k: int,
    metric: array[MaxP*MaxP,int64], p: int): int64 =
  if k == 1: return metric[int(a[0])*p+int(b[0])]
  if k == 2:
    let first = metric[int(a[0])*p+int(b[0])] + metric[int(a[1])*p+int(b[1])]
    let second = metric[int(a[0])*p+int(b[1])] + metric[int(a[1])*p+int(b[0])]
    return min(first,second)
  const Perms: array[6,array[3,int]] = [[0,1,2],[0,2,1],[1,0,2],[1,2,0],[2,0,1],[2,1,0]]
  var best = high(int64)
  for perm in Perms:
    let value = metric[int(a[0])*p+int(b[perm[0]])] + metric[int(a[1])*p+int(b[perm[1]])] + metric[int(a[2])*p+int(b[perm[2]])]
    best = min(best,value)
  best

proc work_function_k_server*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "work_function_k_server".} =
  if input.isNil or length < csize_t(3) or length > csize_t(MaxInput): return -1
  let p64,k64,n64 = input[0],input[1],input[2]
  if p64 < 2 or p64 > 6 or k64 < 1 or k64 > 3 or k64 > p64 or n64 < 0 or n64 > 8: return -1
  let p,k,n = int(p64),int(k64),int(n64)
  let initialAt = 3+p*p
  let requestsAt = initialAt+k
  if int(length) != requestsAt+n: return -1
  var metric: array[MaxP*MaxP,int64]
  for i in 0..<p:
    for j in 0..<p:
      let value = input[3+i*p+j]
      if value < 0 or value > 1000 or (i == j and value != 0) or (i != j and value == 0): return -1
      metric[i*p+j] = value
  for i in 0..<p:
    for j in 0..<p:
      if metric[i*p+j] != metric[j*p+i]: return -1
      for z in 0..<p:
        if metric[i*p+j] > metric[i*p+z]+metric[z*p+j]: return -1
  var initial: array[MaxK,int64]
  for i in 0..<k:
    let value = input[initialAt+i]
    if value < 0 or value >= p64: return -1
    initial[i] = value
    for j in 0..<i:
      if initial[j] == value: return -1
  sortCfg(initial,k)
  var requests: array[MaxR,int64]
  for t in 0..<n:
    requests[t] = input[requestsAt+t]
    if requests[t] < 0 or requests[t] >= p64: return -1
  let outputBytes = 8*(2+n*k)
  if output.isNil or capacity < csize_t(outputBytes): return -2

  var configs: array[MaxConfigs*MaxK,int64]
  var configCount = 0
  for a in 0..<p:
    if k == 1:
      configs[configCount*MaxK] = int64(a); inc configCount
    elif k == 2:
      for b in (a+1)..<p:
        configs[configCount*MaxK] = int64(a); configs[configCount*MaxK+1] = int64(b); inc configCount
    else:
      for b in (a+1)..<p:
        for c in (b+1)..<p:
          configs[configCount*MaxK] = int64(a); configs[configCount*MaxK+1] = int64(b); configs[configCount*MaxK+2] = int64(c); inc configCount
  var work,nextWork: array[MaxConfigs,int64]
  for x in 0..<configCount:
    var cfg: array[MaxK,int64]
    for j in 0..<k: cfg[j] = configs[x*MaxK+j]
    work[x] = configDistance(initial,cfg,k,metric,p)
  var staged: array[2+MaxR*MaxK,int64]
  staged[0] = int64(n); staged[1] = int64(k)
  var current = initial
  for t in 0..<n:
    let request = requests[t]
    for x in 0..<configCount:
      nextWork[x] = high(int64)
      var target: array[MaxK,int64]
      for j in 0..<k: target[j] = configs[x*MaxK+j]
      for y in 0..<configCount:
        var contains = false
        var source: array[MaxK,int64]
        for j in 0..<k:
          source[j] = configs[y*MaxK+j]
          if source[j] == request: contains = true
        if contains:
          nextWork[x] = min(nextWork[x],work[y]+configDistance(source,target,k,metric,p))
    var best = high(int64)
    var bestSlot = 0
    var chosen = current
    var alreadyServed = false
    for j in 0..<k:
      if current[j] == request: alreadyServed = true
    if not alreadyServed:
      for slot in 0..<k:
        var candidate = current
        candidate[slot] = request
        sortCfg(candidate,k)
        let index = findCfg(configs,configCount,candidate,k)
        let score = work[index] + metric[int(current[slot])*p+int(request)]
        if score < best or (score == best and slot < bestSlot):
          best = score; bestSlot = slot; chosen = candidate
    for j in 0..<k:
      staged[2+t*k+j] = chosen[j]
      current[j] = chosen[j]
    for x in 0..<configCount: work[x] = nextWork[x]
  for i in 0..<2+n*k: storeI64LE(output,8*i,staged[i])
  int64(outputBytes)
