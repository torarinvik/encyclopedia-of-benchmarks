const MaxText = 16
const MaxSymbols = 16
const MaxCode = 15
const MaxOutput = 514

type Codes = array[128, array[MaxCode, uint8]]
type Lengths = array[128, uint8]
type Frequencies = array[128, float64]

proc makeCodes(symbols: array[MaxSymbols, uint8], count: int, freq: Frequencies,
    prefix: var array[MaxCode, uint8], depth: int, codes: var Codes, lengths: var Lengths): bool =
  if count == 1:
    for i in 0 ..< depth: codes[int(symbols[0])][i] = prefix[i]
    lengths[int(symbols[0])] = uint8(depth)
    return true
  var total = 0.0
  for i in 0 ..< count: total += freq[int(symbols[i])]
  let capacity = 0.5 * total
  var running = 0.0
  var left, right: array[MaxSymbols, uint8]
  var nl = 0
  var nr = 0
  for i in 0 ..< count:
    let symbol = symbols[i]
    if running + freq[int(symbol)] <= capacity:
      left[nl] = symbol
      inc nl
      running += freq[int(symbol)]
    else:
      right[nr] = symbol
      inc nr
  if nl == 0 or nr == 0 or depth >= MaxCode: return false
  prefix[depth] = uint8(ord('0'))
  if not makeCodes(left, nl, freq, prefix, depth + 1, codes, lengths): return false
  prefix[depth] = uint8(ord('1'))
  makeCodes(right, nr, freq, prefix, depth + 1, codes, lengths)

proc shannon_fano_compressor*(input: ptr UncheckedArray[int64], inputLength: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "shannon_fano_compressor".} =
  if inputLength > 18 or (input == nil and inputLength != 0) or (input != nil and inputLength == 0): return -1
  var textLength = 0
  if input != nil:
    if input[0] < 0 or input[0] > MaxText: return -1
    textLength = int(input[0])
    if inputLength != csize_t(textLength + 1): return -1
  var text: array[MaxText, uint8]
  var symbols: array[MaxSymbols, uint8]
  var seen: array[128, bool]
  var counts: array[128, int]
  var symbolCount = 0
  for i in 0 ..< textLength:
    let value = input[i + 1]
    if value < 0 or value > 127: return -1
    text[i] = uint8(value)
    let s = int(text[i])
    if not seen[s]:
      seen[s] = true
      symbols[symbolCount] = text[i]
      inc symbolCount
    inc counts[s]
  var freq: Frequencies
  if textLength > 0:
    for s in 0 ..< 128: freq[s] = (1.0 * float64(counts[s])) / float64(textLength)
  var codes: Codes
  var lengths: Lengths
  if symbolCount == 1:
    codes[int(symbols[0])][0] = uint8(ord('1'))
    lengths[int(symbols[0])] = 1
  elif symbolCount > 1:
    var prefix: array[MaxCode, uint8]
    if not makeCodes(symbols, symbolCount, freq, prefix, 0, codes, lengths): return -1
  var staged: array[MaxOutput, uint8]
  var n = 0
  var compressedLength = 0
  for i in 0 ..< textLength: compressedLength += int(lengths[int(text[i])])
  staged[n] = uint8(compressedLength); inc n
  for i in 0 ..< textLength:
    let s = int(text[i])
    for j in 0 ..< int(lengths[s]): staged[n] = codes[s][j]; inc n
  staged[n] = uint8(symbolCount); inc n
  for s in 0 ..< 128:
    if lengths[s] != 0:
      staged[n] = uint8(s); inc n
      staged[n] = lengths[s]; inc n
      for j in 0 ..< int(lengths[s]): staged[n] = codes[s][j]; inc n
  if output == nil or capacity < csize_t(n): return -2
  for i in 0 ..< n: output[i] = staged[i]
  int64(n)
