const MaxInputLength = 260
const MaxTextLength = 256
const MaxKey = 256

proc skytale_cipher*(input: ptr UncheckedArray[int64], length: csize_t,
                     output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "skytale_cipher".} =
  if input.isNil or length < 3 or length > MaxInputLength: return -1
  if input[0] < 0 or input[0] > 1 or input[1] < 1 or input[1] > MaxKey or
      input[2] < 0 or input[2] > MaxTextLength: return -1
  let mode = int(input[0])
  let key = int(input[1])
  let n = int(input[2])
  if length != csize_t(3 + n): return -1
  for i in 0 ..< n:
    if input[3 + i] < 0 or input[3 + i] > 127: return -1
  if output.isNil or capacity < csize_t(n): return -2

  if mode == 0:
    var outIndex = 0
    for row in 0 ..< key:
      var position = row
      while position < n:
        output[outIndex] = uint8(input[3 + position])
        inc outIndex
        position += key
  else:
    var starts: array[MaxKey, int]
    var used: array[MaxKey, int]
    let base = n div key
    let extra = n mod key
    for row in 1 ..< key: starts[row] = starts[row - 1] + base + (if row - 1 < extra: 1 else: 0)
    for position in 0 ..< n:
      let row = position mod key
      output[position] = uint8(input[3 + starts[row] + used[row]])
      inc used[row]
  int64(n)
