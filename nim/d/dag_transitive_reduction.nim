const
  MaxN = 8
  MaxM = 28
  MaxLength = 58

proc dag_transitive_reduction*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "dag_transitive_reduction".} =
  if input == nil or length < 2 or length > csize_t(MaxLength + 1): return -1
  if input[0] < 1 or input[0] > int64(MaxN) or input[1] < 0 or input[1] > int64(MaxM): return -1
  let n = int(input[0])
  let m = int(input[1])
  if int(length) != 2 + 2*m: return -1

  var outgoing: array[MaxN, int]
  for edge in 0 ..< m:
    let tailValue = input[2 + 2*edge]
    let headValue = input[3 + 2*edge]
    if tailValue < 0 or headValue < 0 or tailValue >= int64(n) or headValue >= int64(n) or tailValue == headValue:
      return -1
    let tail = int(tailValue)
    let head = int(headValue)
    let bit = 1 shl head
    if (outgoing[tail] and bit) != 0: return -1
    outgoing[tail] = outgoing[tail] or bit

  var reach: array[MaxN, int]
  for vertex in 0 ..< n: reach[vertex] = outgoing[vertex]
  for middle in 0 ..< n:
    for source in 0 ..< n:
      if (reach[source] and (1 shl middle)) != 0:
        reach[source] = reach[source] or reach[middle]
  for vertex in 0 ..< n:
    if (reach[vertex] and (1 shl vertex)) != 0: return -1

  var retained = 0'i64
  for edge in 0 ..< m:
    let tail = int(input[2 + 2*edge])
    let head = int(input[3 + 2*edge])
    var redundant = false
    for middle in 0 ..< n:
      if middle != tail and middle != head and
          (outgoing[tail] and (1 shl middle)) != 0 and (reach[middle] and (1 shl head)) != 0:
        redundant = true
    if not redundant: inc retained
  retained
