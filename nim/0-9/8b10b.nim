const MaxWords = 160
const MaxOutputBytes = 18
const Raw5: array[32, uint16] = [
  0x0d80'u16, 0x05a2'u16, 0x0c60'u16, 0x0cc0'u16, 0x0ca0'u16, 0x10a2'u16, 0x10c2'u16, 0x10e0'u16,
  0x0d20'u16, 0x1122'u16, 0x1142'u16, 0x1160'u16, 0x1182'u16, 0x11a0'u16, 0x11c0'u16, 0x05e0'u16,
  0x0e20'u16, 0x1222'u16, 0x1242'u16, 0x1260'u16, 0x1282'u16, 0x12a0'u16, 0x12c0'u16, 0x06e0'u16,
  0x1302'u16, 0x1320'u16, 0x1340'u16, 0x0760'u16, 0x0380'u16, 0x07a0'u16, 0x0e80'u16, 0x06a2'u16
]
const Raw3: array[8, uint16] = [
  0x0c08'u16, 0x0c04'u16, 0x1009'u16, 0x100c'u16, 0x1011'u16, 0x1014'u16, 0x0018'u16, 0x041c'u16
]

proc encodeOne(packedWord: uint32, disparity: var uint32): uint32 =
  let data = packedWord and 0xff'u32
  let k = packedWord shr 8
  let index5 = int(data shr 3)
  let index3 = int(data and 7'u32)
  var lookup5 = uint32(Raw5[index5])
  var lookup3 = uint32(Raw3[index3])
  if k == 1'u32 and index5 == 7: lookup5 = 0x04e2'u32
  if k == 1'u32:
    if index3 >= 2 and index3 <= 5:
      lookup3 = (lookup3 and not 0x1000'u32) or 0x0800'u32
    elif index3 == 7:
      lookup3 = 0x040d'u32

  var result: uint32
  var disparity1: uint32
  if (lookup5 and 0x1000'u32) != 0'u32:
    result = lookup5 and 0x03e2'u32
    disparity1 = disparity
  else:
    let code5 = lookup5 and 0x03e2'u32
    let plus5 = if (lookup5 and 0x0800'u32) != 0'u32: 1'u32 else: 0'u32
    result = if disparity == plus5: code5 else: code5 xor 0x03e2'u32
    let flip5 = if (lookup5 and 0x0400'u32) != 0'u32: 1'u32 else: 0'u32
    disparity1 = disparity xor flip5

  if (lookup3 and 0x1000'u32) != 0'u32:
    result = result or (lookup3 and 0x001d'u32)
    disparity = disparity1
  else:
    let code3 = lookup3 and 0x001d'u32
    let plus3 = if (lookup3 and 0x0800'u32) != 0'u32: 1'u32 else: 0'u32
    result = result or (if disparity1 == plus3: code3 else: code3 xor 0x001d'u32)
    let flip3 = if (lookup3 and 0x0400'u32) != 0'u32: 1'u32 else: 0'u32
    disparity = disparity1 xor flip3
  result

proc appendLine(value: uint32, staged: var array[MaxOutputBytes, uint8], used: var int) =
  const Hex = "0123456789ABCDEF"
  for digit in 0 ..< 8:
    let shift = (7 - digit) * 4
    staged[used] = uint8(ord(Hex[int((value shr shift) and 15'u32)]))
    inc used
  staged[used] = uint8(ord('\n'))
  inc used

proc versabench8b10bImpl(input: ptr UncheckedArray[int64], inputLength: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 =
  if inputLength > csize_t(MaxWords) or (inputLength > 0 and input == nil): return -1
  let length = int(inputLength)
  for index in 0 ..< length:
    if input[csize_t(index)] < 0 or input[csize_t(index)] > 511: return -1

  let sampleCount = if length == 0: 0 else: 1 + (length - 1) div 128
  let required = sampleCount * 9
  if required > 0 and (output == nil or capacity < csize_t(required)): return -2

  var staged: array[MaxOutputBytes, uint8]
  var used = 0
  var disparity = 0'u32
  for passIndex in 0 ..< length:
    for index in 0 ..< length:
      let encoded = encodeOne(uint32(input[csize_t(index)]), disparity)
      if passIndex + 1 == length and index mod 128 == 0:
        appendLine(encoded, staged, used)

  for index in 0 ..< required:
    output[csize_t(index)] = staged[index]
  int64(used)

proc versabench_8b10b*(input: ptr UncheckedArray[int64], inputLength: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "versabench_8b10b".} =
  versabench8b10bImpl(input, inputLength, output, capacity)
