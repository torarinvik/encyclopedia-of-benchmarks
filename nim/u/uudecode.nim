const
  MaxInputBytes = 4096
  MaxOutputBytes = 2949
  Header = "begin 755 uustart.file \n"

proc scan(input: ptr UncheckedArray[int64], length: int): int =
  if length > MaxInputBytes: return -1
  for i in 0 ..< length:
    if input[i] < 0 or input[i] > 255: return -1
  if length < Header.len + 5: return -1
  for i in 0 ..< Header.len:
    if input[i] != int64(ord(Header[i])): return -1

  var cursor = Header.len
  var total = 0
  while cursor < length:
    let marker = int(input[cursor])
    inc cursor
    if marker == 32:
      if cursor + 4 != length or input[cursor] != 10 or input[cursor + 1] != int64(ord('e')) or
          input[cursor + 2] != int64(ord('n')) or input[cursor + 3] != int64(ord('d')):
        return -1
      if total > MaxOutputBytes: return -1
      return total
    let count = marker - 32
    if count < 1 or count > 45: return -1
    let encoded = 4 * ((count + 2) div 3)
    if cursor + encoded >= length or input[cursor + encoded] != 10: return -1
    for i in 0 ..< encoded:
      if input[cursor + i] < 32 or input[cursor + i] > 95: return -1
    total += count
    if total > MaxOutputBytes: return -1
    cursor += encoded + 1
  return -1

proc uudecode*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "uudecode".} =
  if input.isNil or length > csize_t(MaxInputBytes): return -1
  let count = int(length)
  let decodedLength = scan(input, count)
  if decodedLength < 0: return -1
  if output.isNil or capacity < csize_t(decodedLength): return -2

  var cursor = Header.len
  var written = 0
  while true:
    let lineCount = int(input[cursor]) - 32
    inc cursor
    if lineCount == 0: break
    let encoded = 4 * ((lineCount + 2) div 3)
    var emitted = 0
    for _ in 0 ..< encoded div 4:
      let a = uint32(input[cursor] - 32)
      let b = uint32(input[cursor + 1] - 32)
      let c = uint32(input[cursor + 2] - 32)
      let d = uint32(input[cursor + 3] - 32)
      cursor += 4
      output[written] = uint8(((a shl 2) or (b shr 4)) and 255'u32)
      inc written
      inc emitted
      if emitted < lineCount:
        output[written] = uint8(((b shl 4) or (c shr 2)) and 255'u32)
        inc written
        inc emitted
      if emitted < lineCount:
        output[written] = uint8(((c shl 6) or d) and 255'u32)
        inc written
        inc emitted
    inc cursor
  int64(written)
