proc word_patterns*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "word_patterns".} =
  if input.isNil or length < 1 or input[0] < 0 or input[0] > 256: return -1
  let n = int(input[0])
  if length != csize_t(n + 1): return -1
  var first: array[128, int32]
  for i in 0 ..< 128: first[i] = -1
  var next = 0'i32
  for i in 0 ..< n:
    let ch = input[i + 1]
    if ch < 0 or ch > 127: return -1
    var normalized = ch
    if normalized >= 97 and normalized <= 122: normalized -= 32
    let c = int(normalized)
    if first[c] < 0: first[c] = next; inc next
  if output.isNil or outputCapacity < csize_t(4*n+1): return -2
  var pos = 0
  for i in 0 ..< n:
    var ch = input[i + 1]
    if ch >= 97 and ch <= 122: ch -= 32
    let c = int(ch)
    if i > 0:
      output[pos] = uint8(ord('.'))
      inc pos
    var value = int(first[c])
    var digits: array[3, uint8]
    var count = 0
    while true:
      digits[count] = uint8(ord('0') + value mod 10)
      inc count
      value = value div 10
      if value == 0: break
    while count > 0:
      dec count
      output[pos] = digits[count]
      inc pos
  output[pos] = 0
  int64(pos)
