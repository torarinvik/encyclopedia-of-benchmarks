const MaxInputLength = 4096

proc remove_vowels*(values: ptr UncheckedArray[int64], length: csize_t,
                    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "remove_vowels".} =
  if values.isNil or length < 1 or values[0] < 0 or values[0] > MaxInputLength: return -1
  let n = int(values[0])
  if length != csize_t(n + 1): return -1
  var resultLength = 0
  for i in 0 ..< n:
    if values[i + 1] < 0 or values[i + 1] > 127: return -1
    let c = int(values[i + 1])
    let lowered = if c >= 65 and c <= 90: c + 32 else: c
    if lowered notin [97, 101, 105, 111, 117]: inc resultLength
  if resultLength > int(capacity) or (resultLength > 0 and output.isNil): return -2
  var written = 0
  for i in 0 ..< n:
    let c = int(values[i + 1])
    let lowered = if c >= 65 and c <= 90: c + 32 else: c
    if lowered notin [97, 101, 105, 111, 117]:
      output[written] = uint8(lowered)
      inc written
  int64(written)
