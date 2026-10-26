## Copyright (c) William Landi 1991. Permission to use this code is granted as long as the copyright notice remains in place.
proc prolangs_c_loader_relocation_add*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc.} =
  if input == nil or length < 3 or length > 5: return -1
  let halfBytes = input[0]
  let delta = input[1]
  if halfBytes < 1 or halfBytes > 6 or delta < -65535 or delta > 65535: return -1
  let width = int((halfBytes + 1) div 2)
  if int(length) != 2 + width: return -1
  var field = 0'u32
  for i in 0 ..< width:
    let byte = input[2 + i]
    if byte < 0 or byte > 255: return -1
    field = field * 256 + uint32(byte)
  let adjusted = int64(field) + delta
  if adjusted < 0: return -1
  if capacity < csize_t(width) or output == nil: return -2
  var result = uint32(adjusted)
  for i in countdown(width - 1, 0):
    output[i] = uint8(result and 255)
    result = result shr 8
  int64(width)
