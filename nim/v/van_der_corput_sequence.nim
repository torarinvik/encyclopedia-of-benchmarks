type
  I64Input = ptr UncheckedArray[int64]
  U8Output = ptr UncheckedArray[uint8]

proc storeU64Le(output: U8Output, offset: int, value: uint64) =
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((value shr (byte * 8)) and 255'u64)

proc van_der_corput_sequence*(input: I64Input, length: csize_t, output: U8Output,
    outputCapacity: csize_t): int64 {.cdecl, exportc: "van_der_corput_sequence".} =
  if input == nil or length != 3: return -1
  let base = input[0]
  let firstIndex = input[1]
  let count = input[2]
  if base < 2 or base > 16 or firstIndex < 1 or firstIndex > 4096
      or count < 0 or count > 128
      or (count > 0 and firstIndex + count - 1 > 4096): return -1

  let outputBytes = int(count) * 16
  if output == nil or outputCapacity < csize_t(outputBytes): return -2
  for offset in 0 ..< int(count):
    var index = firstIndex + int64(offset)
    var numerator = 0'u64
    var denominator = 1'u64
    while index > 0:
      numerator = numerator * uint64(base) + uint64(index mod base)
      denominator *= uint64(base)
      index = index div base
    let position = offset * 16
    storeU64Le(output, position, numerator)
    storeU64Le(output, position + 8, denominator)
  int64(outputBytes)
