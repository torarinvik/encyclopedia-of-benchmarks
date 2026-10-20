# Bounded beta=2 lune graph adapted from ParGeo; see benchmarks/b/beta_skeleton/LICENSE.txt.
proc beta_skeleton*(input: ptr UncheckedArray[int64], inputLength: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "beta_skeleton".} =
  if input.isNil or inputLength < 3 or inputLength > 65: return -1
  let nValue = input[0]
  if nValue < 1 or nValue > 32 or inputLength != (1+2*nValue).csize_t: return -1
  let n = int(nValue)
  var x, y: array[32, int64]
  for i in 0 ..< n:
    x[i] = input[1+2*i]; y[i] = input[2+2*i]
    if x[i] < -1000 or x[i] > 1000 or y[i] < -1000 or y[i] > 1000: return -1
    for j in 0 ..< i:
      if x[i] == x[j] and y[i] == y[j]: return -1
  var edges: array[992, uint8]
  var count = 0
  for i in 0 ..< n:
    for j in i+1 ..< n:
      let dx=x[i]-x[j]; let dy=y[i]-y[j]; let d2=dx*dx+dy*dy
      var blocked=false
      for k in 0 ..< n:
        if k == i or k == j: continue
        let aix=x[k]-x[i]; let aiy=y[k]-y[i]; let ajx=x[k]-x[j]; let ajy=y[k]-y[j]
        if aix*aix+aiy*aiy < d2 and ajx*ajx+ajy*ajy < d2: blocked=true; break
      if not blocked: edges[count]=uint8(i); edges[count+1]=uint8(j); count+=2
  if output.isNil or outputCapacity < count.csize_t: return -2
  for i in 0 ..< count: output[i]=edges[i]
  int64(count)
