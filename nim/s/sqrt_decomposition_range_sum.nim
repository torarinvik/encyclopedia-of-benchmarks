const
  MaxN = 64
  MaxOperations = 64
  MaxInputLength = 258

proc blockSizeFor(n: int): int =
  result = 1
  while (result + 1) * (result + 1) <= n:
    inc result

proc querySum(elements, blocks: array[64, int64], blockSize, start, ending: int): int64 =
  let firstIndexNextBlock = ((start div blockSize) + 1) * blockSize
  result = elements[start]
  if firstIndexNextBlock > ending:
    for index in start + 1 ..< ending:
      result += elements[index]
  else:
    for index in start + 1 ..< firstIndexNextBlock:
      result += elements[index]
    let endBlock = ending div blockSize
    for blockIndex in firstIndexNextBlock div blockSize ..< endBlock:
      result += blocks[blockIndex]
    for index in endBlock * blockSize ..< ending:
      result += elements[index]

proc sqrt_decomposition_range_sum*(input: ptr UncheckedArray[int64], length: csize_t,
                                   output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "sqrt_decomposition_range_sum".} =
  if input == nil or length < 3 or length > csize_t(MaxInputLength): return -1
  let nArg = input[0]
  if nArg < 1 or nArg > MaxN: return -1
  let n = int(nArg)
  if length < csize_t(n + 2): return -1
  let operationCountArg = input[n + 1]
  if operationCountArg < 0 or operationCountArg > MaxOperations: return -1
  let operationCount = int(operationCountArg)
  if length != csize_t(2 + n + 3 * operationCount): return -1

  var elements: array[64, int64]
  for index in 0 ..< n:
    let value = input[index + 1]
    if value < -1000 or value > 1000: return -1
    elements[index] = value

  let operationsStart = n + 2
  var queryCount = 0
  for operation in 0 ..< operationCount:
    let offset = operationsStart + 3 * operation
    let kind = input[offset]
    let first = input[offset + 1]
    let second = input[offset + 2]
    if kind == 0:
      if first < 0 or first >= second or second > nArg: return -1
      inc queryCount
    elif kind == 1:
      if first < 0 or first >= nArg or second < -1000 or second > 1000: return -1
    else:
      return -1

  let outputBytes = csize_t(queryCount * 8)
  if output == nil or capacity < outputBytes: return -2

  let blockSize = blockSizeFor(n)
  var blocks: array[64, int64]
  for index in 0 ..< n:
    let block = index div blockSize
    if index mod blockSize == 0: blocks[block] = elements[index]
    else: blocks[block] += elements[index]

  var outputOffset = 0
  for operation in 0 ..< operationCount:
    let offset = operationsStart + 3 * operation
    let kind = input[offset]
    let first = input[offset + 1]
    let second = input[offset + 2]
    if kind == 0:
      let sum = querySum(elements, blocks, blockSize, int(first), int(second))
      let bits = cast[uint64](sum)
      for byte in 0 ..< 8:
        output[outputOffset + byte] = uint8((bits shr (8 * byte)) and 255)
      outputOffset += 8
    else:
      let index = int(first)
      let block = index div blockSize
      blocks[block] = blocks[block] - elements[index] + second
      elements[index] = second
  int64(outputBytes)
