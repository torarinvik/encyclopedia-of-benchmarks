## Myers furthest-reaching edit-graph search for a bounded byte script.
const
  MaxSequence = 16
  MaxDistance = 32
  MaxOutput = 48
  Offset = 33
  Diagonals = 67

type Script = tuple[bytes: array[MaxOutput, uint8], length: int]

proc buildScript(input: ptr UncheckedArray[int64]): Script =
  let n = int(input[0])
  let m = int(input[1])
  var frontier: array[Diagonals, int]
  var trace: array[MaxDistance + 1, array[Diagonals, int]]
  for i in 0 ..< Diagonals: frontier[i] = -1
  for d in 0 .. MaxDistance:
    for i in 0 ..< Diagonals: trace[d][i] = -1
  frontier[Offset + 1] = 0

  var foundDistance = -1
  var foundDiagonal = 0
  for distance in 0 .. n + m:
    var diagonal = -distance
    while diagonal <= distance:
      let slot = Offset + diagonal
      var x: int
      if diagonal == -distance or
          (diagonal != distance and frontier[slot - 1] < frontier[slot + 1]):
        x = frontier[slot + 1]
      else:
        x = frontier[slot - 1] + 1
      var y = x - diagonal
      while x < n and y < m and input[2 + x] == input[2 + n + y]:
        inc x
        inc y
      frontier[slot] = x
      trace[distance][slot] = x
      if x >= n and y >= m:
        foundDistance = distance
        foundDiagonal = diagonal
        break
      diagonal += 2
    if foundDistance >= 0: break

  var reverseOps: array[MaxDistance, uint8]
  var reverseSymbols: array[MaxDistance, uint8]
  var pathLength = 0
  var x = n
  var y = m
  var diagonal = foundDiagonal
  for distance in countdown(foundDistance, 1):
    let slot = Offset + diagonal
    var previousDiagonal, previousX, previousY, snakeX, snakeY: int
    if diagonal == -distance or
        (diagonal != distance and trace[distance - 1][slot - 1] < trace[distance - 1][slot + 1]):
      previousDiagonal = diagonal + 1
      previousX = trace[distance - 1][Offset + previousDiagonal]
      previousY = previousX - previousDiagonal
      snakeX = previousX
      snakeY = previousY + 1
      while x > snakeX and y > snakeY:
        reverseOps[pathLength] = 0
        reverseSymbols[pathLength] = 0
        inc pathLength
        dec x
        dec y
      reverseOps[pathLength] = 2
      reverseSymbols[pathLength] = uint8(input[2 + n + previousY])
      inc pathLength
    else:
      previousDiagonal = diagonal - 1
      previousX = trace[distance - 1][Offset + previousDiagonal]
      previousY = previousX - previousDiagonal
      snakeX = previousX + 1
      snakeY = previousY
      while x > snakeX and y > snakeY:
        reverseOps[pathLength] = 0
        reverseSymbols[pathLength] = 0
        inc pathLength
        dec x
        dec y
      reverseOps[pathLength] = 1
      reverseSymbols[pathLength] = 0
      inc pathLength
    x = previousX
    y = previousY
    diagonal = previousDiagonal

  for i in 0 ..< trace[0][Offset]:
    reverseOps[pathLength] = 0
    reverseSymbols[pathLength] = 0
    inc pathLength

  var bytes: array[MaxOutput, uint8]
  var written = 0
  for i in 0 ..< pathLength:
    let step = pathLength - i - 1
    let operation = reverseOps[step]
    bytes[written] = operation
    inc written
    if operation == 2:
      bytes[written] = reverseSymbols[step]
      inc written
  result = (bytes, written)

proc myers_ond_shortest_edit_script*(input: ptr UncheckedArray[int64], length: csize_t,
                                     output: ptr UncheckedArray[uint8],
                                     outputCapacity: csize_t): int64
    {.cdecl, exportc: "myers_ond_shortest_edit_script".} =
  if input.isNil or length < 2 or length > csize_t(2 + 2 * MaxSequence): return -1
  let nValue = input[0]
  let mValue = input[1]
  if nValue < 0 or nValue > MaxSequence or mValue < 0 or mValue > MaxSequence: return -1
  let n = int(nValue)
  let m = int(mValue)
  if length != csize_t(2 + n + m): return -1
  for i in 0 ..< n + m:
    if input[2 + i] < 0 or input[2 + i] > 255: return -1

  let script = buildScript(input)
  if output.isNil or outputCapacity < csize_t(script.length): return -2
  for i in 0 ..< script.length: output[i] = script.bytes[i]
  int64(script.length)
