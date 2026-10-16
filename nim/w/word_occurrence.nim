const MaxInput = 1024
const MaxEntries = 512
proc ws(c: uint8): bool = (c >= 9 and c <= 13) or (c >= 28 and c <= 32)
proc put32(output: ptr UncheckedArray[uint8], pos: var int, value: uint32) =
  var bits = value
  for _ in 0 ..< 4:
    output[pos] = uint8(bits and 255)
    inc pos
    bits = bits shr 8
proc word_occurrence*(input: ptr UncheckedArray[int64], length: csize_t,
                      output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "word_occurrence".} =
  if input == nil or length < 1 or length > MaxInput + 1: return -1
  let nArg = input[0]
  if nArg < 0 or nArg > 1024 or length != csize_t(nArg + 1): return -1
  let n = int(nArg)
  var text: array[MaxInput, uint8]
  for i in 0 ..< n:
    let value = input[i + 1]
    if value < 0 or value > 127: return -1
    text[i] = uint8(value)
  var starts: array[MaxEntries, int]
  var lens: array[MaxEntries, int]
  var counts: array[MaxEntries, uint32]
  var entries = 0
  var i = 0
  while i < n:
    while i < n and ws(text[i]): inc i
    if i == n: break
    let start = i
    while i < n and not ws(text[i]): inc i
    let tokenLen = i - start
    var entry = 0
    while entry < entries:
      if lens[entry] == tokenLen:
        var offset = 0
        while offset < tokenLen and text[starts[entry] + offset] == text[start + offset]: inc offset
        if offset == tokenLen: break
      inc entry
    if entry == entries:
      if entries >= MaxEntries: return -1
      starts[entry] = start
      lens[entry] = tokenLen
      inc entries
    inc counts[entry]
  var need = 4
  for entry in 0 ..< entries: need += 8 + lens[entry]
  if output == nil or capacity < csize_t(need): return -2
  var pos = 0
  put32(output, pos, uint32(entries))
  for entry in 0 ..< entries:
    put32(output, pos, uint32(lens[entry]))
    for offset in 0 ..< lens[entry]:
      output[pos] = text[starts[entry] + offset]
      inc pos
    put32(output, pos, counts[entry])
  int64(pos)
