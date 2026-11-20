const MaxVertices = 16
const MaxEdges = 64
const MaxIterations = 32
const MaxParseableInputLength = 132
const ScoreScale = 1_000_000'i64

proc hits_fixed_point*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "hits_fixed_point".} =
  if input == nil or length < csize_t(3) or length > csize_t(MaxParseableInputLength):
    return -1

  let nValue = input[0]
  let mValue = input[1]
  let kValue = input[2]
  if nValue < 1 or nValue > MaxVertices or mValue < 0 or mValue > MaxEdges:
    return -1
  if kValue < 0 or kValue > MaxIterations:
    return -1

  let n = int(nValue)
  let m = int(mValue)
  let iterations = int(kValue)
  if length != csize_t(3 + 2 * m):
    return -1

  var sources: array[MaxEdges, int]
  var targets: array[MaxEdges, int]
  var seen: array[MaxVertices * MaxVertices, bool]
  for edge in 0 ..< m:
    let sourceValue = input[3 + 2 * edge]
    let targetValue = input[4 + 2 * edge]
    if sourceValue < 0 or sourceValue >= nValue or targetValue < 0 or targetValue >= nValue:
      return -1
    if sourceValue == targetValue:
      return -1
    let source = int(sourceValue)
    let target = int(targetValue)
    let slot = source * MaxVertices + target
    if seen[slot]:
      return -1
    seen[slot] = true
    sources[edge] = source
    targets[edge] = target

  var hubs: array[MaxVertices, int64]
  var authorities: array[MaxVertices, int64]
  for vertex in 0 ..< n:
    hubs[vertex] = ScoreScale

  for _ in 0 ..< iterations:
    var rawAuthorities: array[MaxVertices, int64]
    for edge in 0 ..< m:
      rawAuthorities[targets[edge]] += hubs[sources[edge]]
    var authorityTotal = 0'i64
    for vertex in 0 ..< n:
      authorityTotal += rawAuthorities[vertex]
    if authorityTotal == 0:
      for vertex in 0 ..< n:
        authorities[vertex] = 0
    else:
      for vertex in 0 ..< n:
        authorities[vertex] = rawAuthorities[vertex] * ScoreScale div authorityTotal

    var rawHubs: array[MaxVertices, int64]
    for edge in 0 ..< m:
      rawHubs[sources[edge]] += authorities[targets[edge]]
    var hubTotal = 0'i64
    for vertex in 0 ..< n:
      hubTotal += rawHubs[vertex]
    if hubTotal == 0:
      for vertex in 0 ..< n:
        hubs[vertex] = 0
    else:
      for vertex in 0 ..< n:
        hubs[vertex] = rawHubs[vertex] * ScoreScale div hubTotal

  var checksum = 0'i64
  for vertex in 0 ..< n:
    checksum += int64(vertex + 1) * (authorities[vertex] + 65537'i64 * hubs[vertex])
  checksum
