import std/math
const MaxText = 512
const AlphabetSize = 128
proc roundEven(value: float64): int =
  let lower = floor(value)
  let fraction = value - lower
  if fraction < 0.5: return int(lower)
  if fraction > 0.5: return int(lower + 1.0)
  let integer = int(lower)
  if integer mod 2 == 0: integer else: integer + 1
proc emitLine(output: var array[32, uint8], posInput: int, valueInput: int): int =
  var pos = posInput
  var value = valueInput
  if value < 0: output[pos] = uint8('-'); inc pos; value = -value
  if value >= 10: output[pos] = uint8(48 + value div 10); inc pos
  output[pos] = uint8(48 + value mod 10); inc pos
  output[pos] = uint8('.'); inc pos
  output[pos] = uint8('0'); inc pos
  output[pos] = uint8(10); inc pos
  pos

## Emit the source's rounded single/bigram entropy values and their difference.
proc entropy*(input: ptr UncheckedArray[int64], length: csize_t, output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "entropy".} =
  if input == nil or length < 2 or length > csize_t(MaxText + 1): return -1
  let n = input[0]
  if n < 1 or n > MaxText or length != csize_t(n + 1): return -1
  var singles: array[AlphabetSize, int64]
  var pairs: array[AlphabetSize * AlphabetSize, int64]
  for i in 0 ..< int(n):
    let ch = input[i + 1]
    if ch < 0 or ch >= AlphabetSize: return -1
    inc singles[int(ch)]
  inc pairs[32 * AlphabetSize + int(input[1])]
  for i in 0 ..< int(n) - 1: inc pairs[int(input[i + 1]) * AlphabetSize + int(input[i + 2])]
  let alpha: array[27, int] = [32, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122]
  var sumSingle = 0.0
  var sumPair = 0.0
  for a in alpha:
    let count = singles[a]
    if count > 0:
      let probability = float64(count) / float64(n)
      sumSingle += probability * log2(probability)
  for a in alpha:
    for b in alpha:
      let count = pairs[a * AlphabetSize + b]
      if count > 0:
        let probability = float64(count) / float64(n)
        sumPair += probability * log2(probability)
  var temp: array[32, uint8]
  var written = emitLine(temp, 0, roundEven(-sumSingle))
  written = emitLine(temp, written, roundEven(-sumPair))
  written = emitLine(temp, written, roundEven((-sumPair) - (-sumSingle)))
  if output == nil or capacity < csize_t(written): return -2
  for i in 0 ..< written: output[i] = temp[i]
  int64(written)
