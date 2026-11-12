const
  MaxVertices = 8
  MaxEdges = 12
  MaxInputLength = 26
  MaxOutputBytes = 96

proc counting_c4*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "counting_c4".} =
  if input == nil or length < 2 or length > csize_t(MaxInputLength):
    return -1
  let nValue = input[0]
  let mValue = input[1]
  if nValue < 2 or nValue > int64(MaxVertices) or mValue < 1 or mValue > int64(MaxEdges):
    return -1
  let n = int(nValue)
  let edgeCount = int(mValue)
  if length != csize_t(2 + 2 * edgeCount):
    return -1

  var multiplicity: array[MaxVertices, array[MaxVertices, int64]]
  for edge in 0 ..< edgeCount:
    let uValue = input[2 + 2 * edge]
    let vValue = input[3 + 2 * edge]
    if uValue < 0 or uValue >= nValue or vValue < 0 or vValue >= nValue or uValue == vValue:
      return -1
    let u = int(uValue)
    let v = int(vValue)
    inc multiplicity[u][v]
    inc multiplicity[v][u]

  var answers: array[MaxEdges, uint64]
  for edge in 0 ..< edgeCount:
    let u = int(input[2 + 2 * edge])
    let v = int(input[3 + 2 * edge])
    for a in 0 ..< n:
      if a == u or a == v:
        continue
      for b in 0 ..< n:
        if b == u or b == v or b == a:
          continue
        answers[edge] += uint64(multiplicity[u][a] * multiplicity[a][b] * multiplicity[b][v])

  let bytes = 8 * edgeCount
  if output == nil or outputCapacity < csize_t(bytes):
    return -2
  var staged: array[MaxOutputBytes, uint8]
  for edge in 0 ..< edgeCount:
    for byte in 0 ..< 8:
      staged[8 * edge + byte] = uint8((answers[edge] shr (8 * byte)) and 0xff'u64)
  for byte in 0 ..< bytes:
    output[byte] = staged[byte]
  int64(bytes)
