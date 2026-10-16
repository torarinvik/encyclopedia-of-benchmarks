const MaxNodes = 128
const MaxOutput = 3589
proc appendI64(buffer: var array[MaxOutput, uint8], start: int, value: int64): int =
  var digits: array[20, uint8]
  var length = 0
  var magnitude = if value < 0: uint64(-(value + 1)) + 1'u64 else: uint64(value)
  while true:
    digits[length] = uint8(ord('0') + int(magnitude mod 10))
    inc length
    magnitude = magnitude div 10
    if magnitude == 0: break
  var p = start
  buffer[p] = uint8(ord('<')); inc p
  if value < 0: buffer[p] = uint8(ord('-')); inc p
  while length > 0:
    dec length
    buffer[p] = digits[length]
    inc p
  buffer[p] = uint8(ord('>')); inc p
  for ch in " ---> ": buffer[p] = uint8(ord(ch)); inc p
  p
proc from_sequence*(v: ptr UncheckedArray[int64], n: csize_t, out: ptr UncheckedArray[uint8], cap: csize_t): int64 {.cdecl, exportc:"from_sequence".} =
  if v == nil or n < 2 or n > csize_t(MaxNodes + 1): return -1
  let count = v[0]
  if count < 1 or count > MaxNodes or n != csize_t(count + 1): return -1
  var buffer: array[MaxOutput, uint8]
  var p = 0
  for i in 0..<int(count): p = appendI64(buffer, p, v[i + 1])
  for ch in "<END>": buffer[p] = uint8(ord(ch)); inc p
  if out == nil or cap < csize_t(p): return -2
  for i in 0..<p: out[i] = buffer[i]
  int64(p)
