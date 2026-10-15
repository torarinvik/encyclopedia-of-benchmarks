proc edgeSpace(value: int64): bool = (value >= 9 and value <= 13) or value == 32
proc digit(value: int64): int =
  if value >= 65 and value <= 90: return int(value - 65)
  if value >= 97 and value <= 122: return int(value - 97 + 26)
  if value >= 48 and value <= 57: return int(value - 48 + 52)
  if value == 43: return 62
  if value == 47: return 63
  -1
proc base64_to_binary*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "base64_to_binary".} =
  if input.isNil or length < 1 or input[0] < 0 or input[0] > 256: return -1
  let n = int(input[0])
  if length != csize_t(n + 1): return -1
  for i in 0..<n:
    if input[i + 1] < 0 or input[i + 1] > 127: return -1
  var begin = 0
  var finish = n
  while begin < finish and edgeSpace(input[begin + 1]): inc begin
  while finish > begin and edgeSpace(input[finish]): dec finish
  if begin == finish: return -1
  let negative = input[begin + 1] == 45
  if negative: inc begin
  for i in begin..<finish:
    if digit(input[i + 1]) < 0: return -1
  let outputLength = (finish - begin) * 6 + (if negative: 1 else: 0)
  if capacity < csize_t(outputLength) or output.isNil: return -2
  var offset = 0
  if negative: output[offset] = uint8(45); inc offset
  for i in begin..<finish:
    let value = digit(input[i + 1])
    for bit in countdown(5, 0):
      output[offset] = uint8(48 + ((value shr bit) and 1))
      inc offset
  int64(outputLength)
