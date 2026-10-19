const
  MaxInputBytes = 4096
  Header = "begin 640 uuencode.c \n"
  Trailer = " \nend"

proc symbol(value: uint32): uint8 {.inline.} =
  uint8(32'u32 + (value and 63'u32))

proc uuencode*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "uuencode".} =
  if input.isNil or length > csize_t(MaxInputBytes): return -1
  let count = int(length)
  for i in 0 ..< count:
    if input[i] < 0 or input[i] > 255: return -1
  let needed = Header.len + 4 * ((count + 2) div 3) +
      2 * ((count + 44) div 45) + Trailer.len
  if output.isNil or capacity < csize_t(needed): return -2

  var cursor = 0
  for ch in Header:
    output[cursor] = uint8(ord(ch))
    inc cursor
  var start = 0
  while start < count:
    let lineLen = min(45, count - start)
    let stop = start + lineLen
    output[cursor] = symbol(uint32(lineLen))
    inc cursor
    var index = start
    while index < stop:
      let a = uint32(input[index])
      let hasB = index + 1 < stop
      let hasC = index + 2 < stop
      let b = if hasB: uint32(input[index + 1]) else: 0'u32
      let c = if hasC: uint32(input[index + 2]) else: 0'u32
      output[cursor] = symbol(a shr 2); inc cursor
      output[cursor] = symbol((a shl 4) or (b shr 4)); inc cursor
      output[cursor] = if hasB: symbol((b shl 2) or (c shr 6)) else: uint8(ord('=')); inc cursor
      output[cursor] = if hasC: symbol(c) else: uint8(ord('=')); inc cursor
      index += 3
    output[cursor] = 10'u8; inc cursor
    start = stop
  for ch in Trailer:
    output[cursor] = uint8(ord(ch))
    inc cursor
  int64(cursor)
