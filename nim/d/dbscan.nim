type I64Array = ptr UncheckedArray[int64]
type ByteArray = ptr UncheckedArray[uint8]

proc dbscan*(input: I64Array, length: csize_t, output: ByteArray, outputCapacity: csize_t): int64
    {.cdecl, exportc: "dbscan".} =
  if input.isNil or length < 5 or length > 67: return -1
  let n0 = input[0]
  let eps = input[1]
  let minimum = input[2]
  if n0 < 1 or n0 > 32 or eps < 1 or eps > 2_000_000 or minimum < 1 or minimum > n0 or length != csize_t(3 + 2 * n0): return -1
  let n = int(n0)
  var x, y: array[32, int64]
  var labels: array[32, int64]
  var expanded: array[32, bool]
  for i in 0 ..< n:
    x[i] = input[3 + 2*i]; y[i] = input[4 + 2*i]; labels[i] = -1
    if x[i] < -1_000_000 or x[i] > 1_000_000 or y[i] < -1_000_000 or y[i] > 1_000_000: return -1
  for i in 0 ..< n:
    for j in 0 ..< i:
      if x[i] == x[j] and y[i] == y[j]: return -1
  if output.isNil or outputCapacity < csize_t(n): return -2
  let e2 = eps * eps
  var next = 0'i64
  for i in 0 ..< n:
    if labels[i] >= 0: continue
    var count = 0
    for j in 0 ..< n:
      let dx=x[i]-x[j]; let dy=y[i]-y[j]
      if dx*dx+dy*dy <= e2: inc count
    if count < int(minimum): continue
    let cluster = next; inc next; labels[i] = cluster
    var queue: array[32, int]
    var queued: array[32, bool]
    var head=0
    var queueEnd=0
    for j in 0 ..< n:
      let dx=x[i]-x[j]; let dy=y[i]-y[j]
      if dx*dx+dy*dy <= e2: queue[queueEnd]=j; inc queueEnd; queued[j]=true
    while head < queueEnd:
      let q=queue[head]; inc head
      if labels[q] >= 0 and labels[q] != cluster: continue
      labels[q]=cluster
      if expanded[q]: continue
      expanded[q]=true
      var nc=0
      for j in 0 ..< n:
        let dx=x[q]-x[j]; let dy=y[q]-y[j]
        if dx*dx+dy*dy <= e2: inc nc
      if nc >= int(minimum):
        for j in 0 ..< n:
          let dx=x[q]-x[j]; let dy=y[q]-y[j]
          if dx*dx+dy*dy <= e2 and labels[j] < 0 and not queued[j]: queue[queueEnd]=j; inc queueEnd; queued[j]=true
  for i in 0 ..< n: output[i] = (if labels[i] < 0: 0'u8 else: uint8(labels[i]+1))
  int64(n)
