const MaxMessageLength = 64
const KeyCount = 26

type I64Array = ptr UncheckedArray[int64]
type ByteArray = ptr UncheckedArray[uint8]

proc brute_force_caesar_cipher*(input: I64Array, length: csize_t, output: ByteArray, capacity: csize_t): int64
    {.cdecl, exportc: "brute_force_caesar_cipher".} =
  if length > csize_t(MaxMessageLength) or (length > 0 and input.isNil): return -1
  let n = int(length)
  for i in 0 ..< n:
    if input[i] < 0 or input[i] > 127: return -1
  let needed = n * KeyCount + (KeyCount - 1)
  if output.isNil or capacity < csize_t(needed): return -2
  var position = 0
  for key in 0 ..< KeyCount:
    for i in 0 ..< n:
      var value = input[i]
      if value >= 65 and value <= 90:
        value = 65 + (value - 65 + 26 - int64(key)) mod 26
      output[position] = uint8(value)
      inc position
    if key + 1 < KeyCount:
      output[position] = uint8(10)
      inc position
  int64(KeyCount)
