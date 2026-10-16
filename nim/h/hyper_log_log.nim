import math

const MaxCount = 1024
const RegisterCount = 65536

proc hyper_log_log*(input: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "hyper_log_log".} =
  if input.isNil or length < 2 or length > csize_t(MaxCount + 1): return -1
  let count64 = input[0]
  if count64 < 1 or count64 > MaxCount or length != csize_t(count64 + 1): return -1
  let count = int(count64)
  for i in 0 ..< count:
    if input[1 + i] < 1 or input[1 + i] > 65535: return -1

  var registers: array[RegisterCount, uint8]
  var seen: array[RegisterCount, uint8]
  var touched: array[MaxCount, uint16]
  for i in 0 ..< RegisterCount:
    registers[i] = 0
    seen[i] = 0
  var touchedCount = 0
  for i in 0 ..< count:
    let value = uint32(input[1 + i])
    var bits = value
    var rank = 0'u8
    while (bits and 1'u32) == 0'u32:
      inc rank
      bits = bits shr 1
    let index = int(value)
    if seen[index] == 0:
      seen[index] = 1
      touched[touchedCount] = uint16(value)
      inc touchedCount
    if rank > registers[index]: registers[index] = rank

  var z = 0.0
  for i in 0 ..< touchedCount:
    let index = int(touched[i])
    z += 1.0 / float64(1'u32 shl int(registers[index]))
  let k = float64(touchedCount)
  int64(ceil(0.673 * k * (k / z)))
