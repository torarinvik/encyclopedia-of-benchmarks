const
  MaxOperations = 64
  MaxParseableLength = 130
  CounterCount = 67
  HashCount = 4

proc hashPositions(key: int64): array[HashCount, int] =
  let first = (17 * key + 3) mod int64(CounterCount)
  let step = 1 + ((5 * key + 3) mod int64(CounterCount - 1))
  for index in 0 ..< HashCount:
    result[index] = int((first + int64(index) * step) mod int64(CounterCount))

proc counting_bloom_filter_operation_trace*(input: ptr UncheckedArray[int64],
    length: csize_t, output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "counting_bloom_filter_operation_trace".} =
  if input.isNil or length < 1 or length > csize_t(MaxParseableLength):
    return -1
  let qValue = input[0]
  if qValue < 0 or qValue > int64(MaxOperations): return -1
  let q = int(qValue)
  if int(length) != 1 + 2 * q: return -1

  for operationIndex in 0 ..< q:
    let opcode = input[1 + 2 * operationIndex]
    let key = input[2 + 2 * operationIndex]
    if opcode < 0 or opcode > 2 or key < 0 or key > 65535: return -1
  if output.isNil or capacity < csize_t(q): return -2

  var counters: array[CounterCount, uint8]
  for operationIndex in 0 ..< q:
    let opcode = input[1 + 2 * operationIndex]
    let key = input[2 + 2 * operationIndex]
    let positions = hashPositions(key)
    if opcode == 0:
      for position in positions: inc counters[position]
      output[operationIndex] = 1
    elif opcode == 1:
      # The caller guarantees each deletion targets a live key.
      for position in positions: dec counters[position]
      output[operationIndex] = 1
    else:
      var present = true
      for position in positions:
        if counters[position] == 0: present = false
      output[operationIndex] = uint8(ord(present))
  int64(q)
