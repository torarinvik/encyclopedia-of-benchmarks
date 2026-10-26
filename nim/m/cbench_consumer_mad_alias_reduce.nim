const Cs: array[8, int64] = [0x0db84a81'i64, 0x0e1b9d7f'i64, 0x0f31adcf'i64, 0x0fbba815'i64,
  0x0feda417'i64, 0x0ffc8fc8'i64, 0x0fff964c'i64, 0x0ffff8d3'i64]
const Ca: array[8, int64] = [-0x083b5fe7'i64, -0x078c36d2'i64, -0x05039814'i64, -0x02e91dd1'i64,
  -0x0183603a'i64, -0x00a7cb87'i64, -0x003a2847'i64, -0x000f27b4'i64]

proc floorDiv(value, divisor: int64): int64 =
  result = value div divisor
  if value mod divisor < 0: dec result

proc madMul(left, right: int64): int64 =
  floorDiv(left + 2048, 4096) * floorDiv(right + 32768, 65536)

proc putI32Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint32](int32(value))
  for byte in 0 ..< 4:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 0xff'u32)

proc cbench_consumer_mad_alias_reduce*(input: ptr UncheckedArray[int64], inputLength: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "cbench_consumer_mad_alias_reduce".} =
  if input == nil or inputLength < 1 or inputLength > 65: return -1
  if input[0] < 1 or input[0] > 4: return -1
  let boundaries = int(input[0])
  if inputLength != csize_t(1 + 16 * boundaries): return -1
  for i in 1 ..< int(inputLength):
    if input[i] < -100_000_000 or input[i] > 100_000_000: return -1
  let outputSize = 64 * boundaries
  var staged: array[64, int64]
  for boundary in 0 ..< boundaries:
    let base = 1 + 16 * boundary
    for i in 0 ..< 8:
      let a = input[base + 2 * i]
      let b = input[base + 2 * i + 1]
      staged[16 * boundary + 2 * i] = madMul(a, Cs[i]) + madMul(-b, Ca[i])
      staged[16 * boundary + 2 * i + 1] = madMul(b, Cs[i]) + madMul(a, Ca[i])
  if output == nil or outputCapacity < csize_t(outputSize): return -2
  for i in 0 ..< 16 * boundaries: putI32Le(output, 4 * i, staged[i])
  int64(outputSize)
