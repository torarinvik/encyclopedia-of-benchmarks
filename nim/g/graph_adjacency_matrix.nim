const
  MaxVertices = 8
  MaxVertexIdExclusive = 32
  MaxEdges = 64
  MaxOperations = 24

proc putI64Le(output: ptr UncheckedArray[uint8], word: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0..<8: output[word*8+byte] = uint8((bits shr (byte*8)) and 255'u64)

proc vertexIndex(vertices: array[MaxVertices, int], count, value: int): int =
  for index in 0..<count:
    if vertices[index] == value: return index
  return -1

proc removeVertex(vertices: var array[MaxVertices, int], matrix: var array[MaxVertices * MaxVertices, int], count: var int, index: int) =
  let oldCount = count
  for row in index..<oldCount-1:
    vertices[row] = vertices[row+1]
    for column in 0..<oldCount: matrix[row*MaxVertices+column] = matrix[(row+1)*MaxVertices+column]
  for row in 0..<oldCount-1:
    for column in index..<oldCount-1: matrix[row*MaxVertices+column] = matrix[row*MaxVertices+column+1]
  for i in 0..<oldCount:
    matrix[(oldCount-1)*MaxVertices+i] = 0
    matrix[i*MaxVertices+oldCount-1] = 0
  count = oldCount-1

proc graph_adjacency_matrix*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "graph_adjacency_matrix".} =
  if input == nil or length < 4: return -1
  let directedValue = input[0]
  let countValue = input[1]
  if (directedValue != 0 and directedValue != 1) or countValue < 0 or countValue > MaxVertices: return -1
  var count = int(countValue)
  if length < csize_t(3+count): return -1
  var vertices: array[MaxVertices, int]
  var matrix: array[MaxVertices * MaxVertices, int]
  var position = 2
  for i in 0..<count:
    let value = input[position]
    inc position
    if value < 0 or value >= MaxVertexIdExclusive or vertexIndex(vertices, i, int(value)) >= 0: return -1
    vertices[i] = int(value)
  if csize_t(position) >= length: return -1
  let edgeValue = input[position]
  inc position
  if edgeValue < 0 or edgeValue > MaxEdges or length < csize_t(position+2*int(edgeValue)+1): return -1
  for _ in 0..<int(edgeValue):
    let sourceValue = input[position]
    let destinationValue = input[position+1]
    position += 2
    if sourceValue < 0 or sourceValue >= MaxVertexIdExclusive or destinationValue < 0 or destinationValue >= MaxVertexIdExclusive: return -1
    let source = vertexIndex(vertices, count, int(sourceValue))
    let destination = vertexIndex(vertices, count, int(destinationValue))
    if source < 0 or destination < 0 or matrix[source*MaxVertices+destination] != 0: return -1
    matrix[source*MaxVertices+destination] = 1
    if directedValue == 0: matrix[destination*MaxVertices+source] = 1
  let operationValue = input[position]
  inc position
  if operationValue < 0 or operationValue > MaxOperations or length != csize_t(position+3*int(operationValue)): return -1
  let operationCount = int(operationValue)
  var results: array[MaxOperations, int]
  for operationIndex in 0..<operationCount:
    let operation = input[position]
    let aValue = input[position+1]
    let bValue = input[position+2]
    position += 3
    if operation == 0:
      if aValue < 0 or aValue >= MaxVertexIdExclusive or bValue != 0 or count >= MaxVertices or vertexIndex(vertices, count, int(aValue)) >= 0: return -1
      for i in 0..<MaxVertices:
        matrix[i*MaxVertices+count] = 0
        matrix[count*MaxVertices+i] = 0
      vertices[count] = int(aValue)
      inc count
      results[operationIndex] = 1
    elif operation == 1:
      if aValue < 0 or aValue >= MaxVertexIdExclusive or bValue != 0: return -1
      let removed = vertexIndex(vertices, count, int(aValue))
      if removed < 0: return -1
      removeVertex(vertices, matrix, count, removed)
      results[operationIndex] = 1
    elif operation == 2 or operation == 3 or operation == 5:
      if aValue < 0 or aValue >= MaxVertexIdExclusive or bValue < 0 or bValue >= MaxVertexIdExclusive: return -1
      let source = vertexIndex(vertices, count, int(aValue))
      let destination = vertexIndex(vertices, count, int(bValue))
      if source < 0 or destination < 0: return -1
      let cell = source*MaxVertices+destination
      let present = matrix[cell] != 0
      if operation == 5:
        results[operationIndex] = if present: 1 else: 0
      elif operation == 2:
        if present: return -1
        matrix[cell] = 1
        if directedValue == 0: matrix[destination*MaxVertices+source] = 1
        results[operationIndex] = 1
      else:
        if not present: return -1
        matrix[cell] = 0
        if directedValue == 0: matrix[destination*MaxVertices+source] = 0
        results[operationIndex] = 1
    elif operation == 4:
      if aValue < 0 or aValue >= MaxVertexIdExclusive or bValue != 0: return -1
      results[operationIndex] = if vertexIndex(vertices, count, int(aValue)) >= 0: 1 else: 0
    elif operation == 6:
      if aValue != 0 or bValue != 0: return -1
      count = 0
      for cell in 0..<MaxVertices*MaxVertices: matrix[cell] = 0
      results[operationIndex] = 1
    else:
      return -1

  let words = 2+operationCount+count+count*count
  if output == nil or capacity < csize_t(words*8): return -2
  var word = 0
  putI64Le(output, word, int64(operationCount)); inc word
  for i in 0..<operationCount: putI64Le(output, word, int64(results[i])); inc word
  putI64Le(output, word, int64(count)); inc word
  for i in 0..<count: putI64Le(output, word, int64(vertices[i])); inc word
  for row in 0..<count:
    for column in 0..<count: putI64Le(output, word, int64(matrix[row*MaxVertices+column])); inc word
  int64(words*8)
