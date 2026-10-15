const Alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
proc edgeSpace(value: int64): bool = (value >= 9 and value <= 13) or value == 32

proc binary_to_base64*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "binary_to_base64".} =
  if input.isNil or length < 2 or input[0] < 1 or input[0] > 256: return -1
  let n = int(input[0])
  if length != csize_t(n + 1): return -1
  for i in 0..<n:
    if input[1 + i] < 0 or input[1 + i] > 127: return -1
  var begin = 0
  var finish = n
  while begin < finish and edgeSpace(input[1 + begin]): inc begin
  while finish > begin and edgeSpace(input[finish]): dec finish
  if begin == finish: return -1
  let negative = input[1 + begin] == 45
  if negative: inc begin
  for i in begin..<finish:
    if input[1 + i] != 48 and input[1 + i] != 49: return -1
  let bitCount = finish - begin
  let padding = 6 - bitCount mod 6
  let groups = (bitCount + padding) div 6
  let outputLength = groups + (if negative: 1 else: 0)
  if capacity < csize_t(outputLength) or output.isNil: return -2
  var offset = 0
  if negative: output[offset] = uint8(ord('-')); inc offset
  for group in 0..<groups:
    var value = 0
    for bit in 0..<6:
      value = value shl 1
      let position = group * 6 + bit
      if position >= padding and input[1 + begin + position - padding] == 49: inc value
    output[offset] = uint8(Alphabet[value].ord)
    inc offset
  int64(outputLength)
