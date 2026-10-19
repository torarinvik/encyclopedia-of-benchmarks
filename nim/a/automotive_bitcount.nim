const
  MaxIterations = 1_125_000'i64
  NibbleBits: array[16, int32] = [0'i32, 1, 1, 2, 1, 2, 2, 3, 1, 2, 2, 3, 2, 3, 3, 4]
  InitialSeeds: array[7, uint32] = [16839'u32, 18985, 21520, 3905, 10113, 8672, 21285]

proc countKernighan(valueInput: uint32): int32 =
  var value = valueInput
  var count = 0'i32
  while value != 0:
    value = value and (value - 1'u32)
    inc count
  count

proc countParallel(valueInput: uint32): int32 =
  var value = valueInput
  value = ((value and 0xAAAAAAAA'u32) shr 1) + (value and 0x55555555'u32)
  value = ((value and 0xCCCCCCCC'u32) shr 2) + (value and 0x33333333'u32)
  value = ((value and 0xF0F0F0F0'u32) shr 4) + (value and 0x0F0F0F0F'u32)
  value = ((value and 0xFF00FF00'u32) shr 8) + (value and 0x00FF00FF'u32)
  value = ((value and 0xFFFF0000'u32) shr 16) + (value and 0x0000FFFF'u32)
  int32(value)

proc countRecursiveNybbles(value: uint32): int32 =
  let count = NibbleBits[int(value and 0xF'u32)]
  if (value shr 4) == 0: return count
  count + countRecursiveNybbles(value shr 4)

proc countFixedNybbles(value: uint32): int32 =
  var count = 0'i32
  for shift in countup(0, 28, 4):
    count += NibbleBits[int((value shr shift) and 0xF'u32)]
  count

proc countByte(value: uint32): int32 =
  NibbleBits[int(value and 0xF'u32)] + NibbleBits[int((value shr 4) and 0xF'u32)]

proc countBwBytes(value: uint32): int32 =
  countByte(value) + countByte(value shr 8) + countByte(value shr 24) + countByte(value shr 16)

proc countArBytes(value: uint32): int32 =
  var count = 0'i32
  for index in 0 ..< 4:
    count += countByte(value shr (index * 8))
  count

proc countShiftTest(valueInput: uint32): int32 =
  var value = valueInput
  var count = 0'i32
  var bit = 0
  while bit < 64 and value != 0:
    count += int32(value and 1'u32)
    value = value shr 1
    inc bit
  count

proc countSelected(algorithm: int, value: uint32): int32 =
  case algorithm
  of 0: countKernighan(value)
  of 1: countParallel(value)
  of 2: countRecursiveNybbles(value)
  of 3: countFixedNybbles(value)
  of 4: countBwBytes(value)
  of 5: countArBytes(value)
  else: countShiftTest(value)

proc automotive_bitcount*(iterations: int64): int64 {.cdecl, exportc: "automotive_bitcount".} =
  if iterations < 0 or iterations > MaxIterations: return -1
  var result = 0'i64
  for algorithm in 0 ..< 7:
    var seed = InitialSeeds[algorithm]
    var total = 0'i64
    var iteration = 0'i64
    while iteration < iterations:
      total += int64(countSelected(algorithm, seed))
      seed += 13'u32
      inc iteration
    result += int64(algorithm + 1) * total
  result
