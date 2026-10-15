type I64Input = ptr UncheckedArray[int64]

proc gray_to_decimal*(values: I64Input, length: csize_t): int64 {.cdecl, exportc: "gray_to_decimal".} =
  if values == nil or length < 2 or length > 64: return -1
  let bitLength = values[0]
  if bitLength < 1 or bitLength > 63 or length != csize_t(bitLength + 1): return -1

  var prefix = 0'i64
  var binary = 0'i64
  for index in 1 ..< int(length):
    let character = values[index]
    if character != 48 and character != 49: return -1
    prefix = prefix xor (character - 48)
    binary = binary * 2 + prefix
  binary
