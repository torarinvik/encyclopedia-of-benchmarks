const
  MaxLength = 256
  MinValue = -1_000_000'i64
  MaxValue = 1_000_000'i64
  ChecksumOffset = 1_000_001'i64
  InvalidResult = -1'i64

proc improved_simple_sort*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "improved_simple_sort".} =
  if length > csize_t(MaxLength) or (length != 0 and values.isNil): return InvalidResult
  var working: array[MaxLength, int64]
  let inputLength = int(length)
  for index in 0 ..< inputLength:
    if values[index] < MinValue or values[index] > MaxValue: return InvalidResult
    working[index] = values[index]

  var i = 1
  while i < inputLength:
    var j = 0
    while j + 1 < inputLength:
      if working[i] < working[j]: swap(working[i], working[j])
      inc j
    inc i
  var checksum = 0'i64
  for index in 0 ..< inputLength:
    checksum += int64(index + 1) * (working[index] + ChecksumOffset)
  checksum
