const
  MaxH = 32
  MaxW = 32
  MaxQ = 128
  MaxInput = 1540
  MaxOutput = 1024
  Modulus = 1_000_000_007'i64
  RowBase = 31'i64
  ColBase = 37'i64

proc rolling_hash_2d_rectangle_query*(input: ptr UncheckedArray[int64], length: csize_t,
                                      output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "rolling_hash_2d_rectangle_query".} =
  if input == nil or length < 3 or length > csize_t(MaxInput): return -1
  let hValue = input[0]
  let wValue = input[1]
  let qValue = input[2]
  if hValue < 1 or hValue > int64(MaxH) or wValue < 1 or wValue > int64(MaxW) or
      qValue < 1 or qValue > int64(MaxQ): return -1
  let h = int(hValue)
  let w = int(wValue)
  let q = int(qValue)
  if int(length) != 3 + h*w + 4*q: return -1
  let queryOffset = 3 + h*w
  for i in 0 ..< h*w:
    if input[3+i] < 0 or input[3+i] > 255: return -1
  for i in 0 ..< q:
    let r0 = input[queryOffset + 4*i]
    let c0 = input[queryOffset + 4*i + 1]
    let r1 = input[queryOffset + 4*i + 2]
    let c1 = input[queryOffset + 4*i + 3]
    if r0 < 0 or r0 > r1 or r1 > hValue or c0 < 0 or c0 > c1 or c1 > wValue: return -1
  let required = 8*q
  if output == nil or capacity < csize_t(required): return -2

  var rowPower: array[MaxH + 1, int64]
  var colPower: array[MaxW + 1, int64]
  rowPower[0] = 1
  colPower[0] = 1
  for i in 1 .. h: rowPower[i] = rowPower[i-1] * RowBase mod Modulus
  for j in 1 .. w: colPower[j] = colPower[j-1] * ColBase mod Modulus
  var prefix: array[MaxH + 1, array[MaxW + 1, int64]]
  for r in 1 .. h:
    var rowHash = 0'i64
    for c in 1 .. w:
      rowHash = (rowHash * ColBase + input[3 + (r-1)*w + c-1]) mod Modulus
      prefix[r][c] = (prefix[r-1][c] * RowBase + rowHash) mod Modulus
  var staged: array[MaxOutput, uint8]
  for i in 0 ..< q:
    let r0 = int(input[queryOffset + 4*i])
    let c0 = int(input[queryOffset + 4*i + 1])
    let r1 = int(input[queryOffset + 4*i + 2])
    let c1 = int(input[queryOffset + 4*i + 3])
    let rh = r1 - r0
    let cw = c1 - c0
    var value = prefix[r1][c1] - prefix[r0][c1] * rowPower[rh] mod Modulus -
      prefix[r1][c0] * colPower[cw] mod Modulus +
      prefix[r0][c0] * rowPower[rh] mod Modulus * colPower[cw] mod Modulus
    value = value mod Modulus
    if value < 0: value += Modulus
    let bits = cast[uint64](value)
    for byte in 0 ..< 8: staged[8*i + byte] = uint8((bits shr (8*byte)) and 255)
  for i in 0 ..< required: output[i] = staged[i]
  int64(required)
