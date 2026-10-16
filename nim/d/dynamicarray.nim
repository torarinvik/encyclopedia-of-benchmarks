proc dynamicarray*(input: ptr UncheckedArray[int64], length: csize_t,
                   output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "dynamicarray".} =
  if input == nil or length < 1 or length > 385 or input[0] < 0 or input[0] > 128: return -1
  var a: array[64, int64]
  var b: array[64, int64]
  var queries: array[128, int64]
  var size = 0
  var capacity = 0
  var cursor = 1
  var queryCount = 0
  var active = 0
  for oi in 0 ..< int(input[0]):
    if cursor >= int(length): return -1
    let op = input[cursor]
    inc cursor
    if op == 0:
      if cursor >= int(length) or size >= 64: return -1
      if size == capacity:
        if active == 0:
          for i in 0 ..< size: b[i] = a[i]
          active = 1
        else:
          for i in 0 ..< size: a[i] = b[i]
          active = 0
        capacity = if capacity == 0: 10 else: capacity * 2
      if active == 0: a[size] = input[cursor] else: b[size] = input[cursor]
      inc size
      inc cursor
    elif op == 1:
      if cursor + 1 >= int(length): return -1
      let index = input[cursor]
      let value = input[cursor + 1]
      cursor += 2
      if index < 0 or index >= int64(size): return -1
      if active == 0: a[int(index)] = value else: b[int(index)] = value
    elif op == 2 or op == 3:
      if cursor >= int(length): return -1
      let index = input[cursor]
      inc cursor
      if index < 0 or index >= int64(size): return -1
      let at = int(index)
      if op == 2:
        if queryCount >= 128: return -1
        queries[queryCount] = if active == 0: a[at] else: b[at]
        inc queryCount
      elif active == 0:
        for i in at ..< size - 1: a[i] = a[i + 1]
        dec size
      else:
        for i in at ..< size - 1: b[i] = b[i + 1]
        dec size
    elif op >= 4 and op <= 6:
      if queryCount >= 128: return -1
      if op == 4: queries[queryCount] = int64(size)
      elif op == 5: queries[queryCount] = int64(capacity)
      else: queries[queryCount] = (if size == 0: 1'i64 else: 0'i64)
      inc queryCount
    else: return -1
  if cursor != int(length): return -1
  let words = 3 + queryCount + size
  if output == nil or outputCapacity < csize_t(words * 8): return -2
  proc writeWord(index: int, value: int64) =
    var bits = cast[uint64](value)
    for byte in 0 ..< 8:
      output[index * 8 + byte] = uint8(bits and 255)
      bits = bits shr 8
  writeWord(0, int64(queryCount))
  for i in 0 ..< queryCount: writeWord(i + 1, queries[i])
  writeWord(queryCount + 1, int64(size))
  writeWord(queryCount + 2, int64(capacity))
  for i in 0 ..< size: writeWord(queryCount + 3 + i, if active == 0: a[i] else: b[i])
  int64(words)
