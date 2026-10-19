proc crcByte(value0: uint8, crc0: uint16): uint16 =
  var value = value0; var crc = crc0
  for _ in 0..<8:
    let mix = (value and 1) xor uint8(crc and 1)
    value = value shr 1
    if mix != 0: crc = crc xor 0x4002'u16
    crc = crc shr 1
    if mix != 0: crc = crc or 0x8000'u16
    else: crc = crc and 0x7fff'u16
  crc

proc crc16(value: int16, crc: uint16): uint16 =
  let bits = cast[uint16](value)
  crcByte(uint8(bits shr 8), crcByte(uint8(bits), crc))

proc matrixSum(c: array[9,int32], clip: int16): int16 =
  var tmp = 0'i32; var prev = 0'i32; var ret = 0'i16
  for cur in c:
    tmp += cur
    if tmp > int32(clip):
      ret += 10
      tmp = 0
    elif cur > prev: ret += 1
    prev = cur
  ret

proc putI64(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for b in 0..<8: output[offset+b] = uint8(bits shr (8*b))

proc coremark_matrix_manipulation*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "coremark_matrix_manipulation".} =
  if input.isNil or length != 19: return -1
  let raw = input[0]
  if raw < 0 or raw > 15: return -1
  var a, b: array[9,int16]
  for i in 0..<9:
    if input[1+i] < 0 or input[1+i] > 127 or input[10+i] < 0 or input[10+i] > 127: return -1
    a[i] = int16(input[1+i]); b[i] = int16(input[10+i])
  if output.isNil or capacity < 112: return -2
  let value = int16(raw); let clip = value - 4096
  var c: array[9,int32]
  var sums: array[4,int16]
  for i in 0..<9: a[i] += value
  for i in 0..<9: c[i] = int32(a[i]) * int32(value)
  sums[0] = matrixSum(c, clip)
  for i in 0..<3:
    c[i] = 0
    for j in 0..<3: c[i] += int32(a[i*3+j]) * int32(b[j])
  sums[1] = matrixSum(c, clip)
  for i in 0..<3:
    for j in 0..<3:
      c[i*3+j] = 0
      for k in 0..<3: c[i*3+j] += int32(a[i*3+k]) * int32(b[k*3+j])
  sums[2] = matrixSum(c, clip)
  for i in 0..<3:
    for j in 0..<3:
      c[i*3+j] = 0
      for k in 0..<3:
        let product = int32(a[i*3+k]) * int32(b[k*3+j])
        c[i*3+j] += ((product shr 2) and 0xF) * ((product shr 5) and 0x7F)
  sums[3] = matrixSum(c, clip)
  var crc = 0'u16
  for s in sums: crc = crc16(s, crc)
  for i in 0..<9: a[i] -= value
  var encoded: array[14,int64]
  encoded[0] = int64(crc)
  for i in 0..<4: encoded[i+1] = int64(sums[i])
  for i in 0..<9: encoded[i+5] = int64(a[i])
  for i in 0..<14: putI64(output, i*8, encoded[i])
  112
