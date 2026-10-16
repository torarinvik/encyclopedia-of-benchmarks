const
  MaxVertices = 8
  MaxEdges = 56
  Infinity = high(int64) div 4

proc putI64Le(output: ptr UncheckedArray[uint8], word: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0..<8: output[word*8+byte] = uint8((bits shr (byte*8)) and 255'u64)

proc graph_peripherality*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "graph_peripherality".} =
  if input == nil or length < 2: return -1
  let nValue = input[0]
  let edgeValue = input[1]
  if nValue < 1 or nValue > MaxVertices or edgeValue < 0 or edgeValue > MaxEdges or
      edgeValue > nValue*(nValue-1) or length != csize_t(2+3*edgeValue): return -1
  let n = int(nValue)
  let edgeCount = int(edgeValue)
  var distance: array[MaxVertices, array[MaxVertices, int64]]
  for i in 0..<n:
    for j in 0..<n: distance[i][j] = if i == j: 0 else: Infinity
  for edge in 0..<edgeCount:
    let sourceValue = input[2+3*edge]
    let destinationValue = input[3+3*edge]
    let weight = input[4+3*edge]
    if sourceValue < 0 or sourceValue >= nValue or destinationValue < 0 or destinationValue >= nValue or
        sourceValue == destinationValue or weight < 1 or weight > 1_000_000: return -1
    let source = int(sourceValue)
    let destination = int(destinationValue)
    if distance[source][destination] != Infinity: return -1
    distance[source][destination] = weight
  for middle in 0..<n:
    for source in 0..<n:
      if distance[source][middle] == Infinity: continue
      for destination in 0..<n:
        if distance[middle][destination] != Infinity:
          let candidate = distance[source][middle] + distance[middle][destination]
          if candidate < distance[source][destination]: distance[source][destination] = candidate
  if n > 1:
    for source in 0..<n:
      for destination in 0..<n:
        if source != destination and distance[source][destination] == Infinity: return -1
  var peripheral = -1
  var far = -1
  var peripheralInfinite = false
  var farInfinite = false
  var anyReachable = false
  var bestEccentricity = -1'i64
  var bestFarness = -1'i64
  if n == 1:
    peripheral = 0
    far = 0
    bestEccentricity = 0
    bestFarness = 0
  else:
    for source in 0..<n:
      var found = false
      var eccentricity = 0'i64
      var farness = 0'i64
      for destination in 0..<n:
        let value = distance[source][destination]
        if destination == source or value == Infinity or value == 0: continue
        found = true
        if value > eccentricity: eccentricity = value
        farness += value
      if found: anyReachable = true
      let infinite = not found
      if peripheral < 0 or (infinite and not peripheralInfinite) or
          (infinite == peripheralInfinite and (infinite or eccentricity > bestEccentricity or
           (eccentricity == bestEccentricity and source < peripheral))):
        peripheral = source
        peripheralInfinite = infinite
        bestEccentricity = eccentricity
      if far < 0 or (infinite and not farInfinite) or
          (infinite == farInfinite and (infinite or farness > bestFarness or
           (farness == bestFarness and source < far))):
        far = source
        farInfinite = infinite
        bestFarness = farness
    if not anyReachable:
      peripheral = -1
      far = -1
      bestEccentricity = -1
      bestFarness = -1
    else:
      if peripheralInfinite: bestEccentricity = -1
      if farInfinite: bestFarness = -1
  if output == nil or capacity < 32: return -2
  putI64Le(output, 0, int64(peripheral))
  putI64Le(output, 1, bestEccentricity)
  putI64Le(output, 2, int64(far))
  putI64Le(output, 3, bestFarness)
  32
