const factorLog32: array[32, uint32] = [
  0x00000000'u32, 0x00000000'u32, 0xd3cfd984'u32, 0x9ee62e18'u32,
  0xe83d9070'u32, 0xb59e81e0'u32, 0xa17407c0'u32, 0xce601f80'u32,
  0xf4807f00'u32, 0xe701fe00'u32, 0xbe07fc00'u32, 0xfc1ff800'u32,
  0xf87ff000'u32, 0xf1ffe000'u32, 0xe7ffc000'u32, 0xdfff8000'u32,
  0xffff0000'u32, 0xfffe0000'u32, 0xfffc0000'u32, 0xfff80000'u32,
  0xfff00000'u32, 0xffe00000'u32, 0xffc00000'u32, 0xff800000'u32,
  0xff000000'u32, 0xfe000000'u32, 0xfc000000'u32, 0xf8000000'u32,
  0xf0000000'u32, 0xe0000000'u32, 0xc0000000'u32, 0x80000000'u32]

proc factoringMask(d: int): uint64 =
  if d == 32: return 0xffffffff'u64
  (1'u64 shl d) - 1'u64

proc factoringLog(remainderInput, valueInput: uint64, d: int,
                  modulus, mask: uint64): uint64 =
  var remainder = remainderInput
  var value = valueInput
  for bit in 2 ..< d:
    if (value and (1'u64 shl bit)) != 0:
      value = (value + (value shl bit)) and mask
      remainder = (remainder + modulus - (uint64(factorLog32[bit]) and mask)) and mask
  remainder

proc factoringExp(remainderInput, exponentInput: uint64, d: int,
                  modulus, mask: uint64): uint64 =
  var remainder = remainderInput
  var exponent = exponentInput
  for bit in 2 ..< d:
    if (exponent and (1'u64 shl bit)) != 0:
      remainder = (remainder + (remainder shl bit)) and mask
      exponent = (exponent + modulus - (uint64(factorLog32[bit]) and mask)) and mask
  remainder

proc factoring_exponentiation*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "factoring_exponentiation".} =
  if input == nil or length != 4: return -1
  let remainderInput = input[0]
  let baseInput = input[1]
  let exponentInput = input[2]
  let dInput = input[3]
  if dInput < 3 or dInput > 32 or remainderInput < 0 or baseInput < 1 or
      exponentInput < 0 or exponentInput > 4294967295'i64: return -1
  let d = int(dInput)
  let mask = factoringMask(d)
  let modulus = mask + 1'u64
  if uint64(remainderInput) >= modulus or uint64(baseInput) >= modulus or
      (uint64(baseInput) and 1'u64) == 0: return -1

  var remainder = uint64(remainderInput)
  var base = uint64(baseInput)
  let exponent = uint64(exponentInput)
  if (base and 2'u64) != 0:
    base = (modulus - base) and mask
    if (exponent and 1'u64) != 0: remainder = (modulus - remainder) and mask
  let logValue = factoringLog(0'u64, base, d, modulus, mask)
  let scaledLog = (logValue * exponent) and mask
  int64(factoringExp(remainder, scaledLog, d, modulus, mask))
