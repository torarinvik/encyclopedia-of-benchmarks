const MaxText = 256
const MaxInput = 259

proc transposition_cipher*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "transposition_cipher".} =
  if input.isNil or length < 6 or length > csize_t(MaxInput): return -1
  let mode = input[0]
  let key64 = input[1]
  let n64 = input[2]
  if (mode != 0 and mode != 1) or n64 < 3 or n64 > MaxText or key64 < 2 or key64 >= n64: return -1
  let n = int(n64)
  let key = int(key64)
  if int(length) != 3 + n: return -1
  for i in 0 ..< n:
    if input[3 + i] < 0 or input[3 + i] > 127: return -1
  if output.isNil or outputCapacity < csize_t(n): return -2

  var transformed: array[MaxText, uint8]
  if mode == 0:
    var written = 0
    for column in 0 ..< key:
      var index = column
      while index < n:
        transformed[written] = uint8(input[3 + index])
        inc written
        index += key
  else:
    let columns = (n + key - 1) div key
    let shaded = columns * key - n
    let finalColumnRows = key - shaded
    var offsets: array[MaxText, int]
    var seen: array[MaxText, int]
    var total = 0
    for column in 0 ..< columns:
      offsets[column] = total
      total += (if column + 1 == columns: finalColumnRows else: key)
    var row = 0
    var column = 0
    for i in 0 ..< n:
      transformed[offsets[column] + seen[column]] = uint8(input[3 + i])
      inc seen[column]
      inc column
      if column == columns or (column == columns - 1 and row >= finalColumnRows):
        column = 0
        inc row
  for i in 0 ..< n: output[i] = transformed[i]
  int64(n)
