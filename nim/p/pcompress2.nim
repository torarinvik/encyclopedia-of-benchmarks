## Clean-room bounded pcompress2 compression pipeline.
## Based on lac-dcc/Benchmarks FreeBench/pcompress2 at 5d7b75d; no license grant was found.
const MaxLength = 32
const MaxOutput = 8 + MaxLength * 16
const Symbols = 257

type BitWriter = object
  bytes: ptr UncheckedArray[uint8]
  length: int
  buffer: uint8
  bitsToGo: int

proc rotationLess(input: ptr UncheckedArray[uint8], n, left, right: int): bool =
  for offset in 0 ..< n:
    let a = input[(left + offset) mod n]
    let b = input[(right + offset) mod n]
    if a != b: return a < b
  left < right

proc outputBit(w: var BitWriter, bit: int) =
  w.buffer = w.buffer shr 1
  if bit != 0: w.buffer = w.buffer or 0x80'u8
  dec w.bitsToGo
  if w.bitsToGo == 0:
    w.bytes[w.length] = w.buffer
    inc w.length
    w.bitsToGo = 8

proc bitPlusFollow(w: var BitWriter, bit: int, follow: var int) =
  w.outputBit(bit)
  while follow > 0:
    w.outputBit(1 - bit)
    dec follow

proc encodeSymbol(symbol: int, cum: array[258, int], low, high: var uint32,
                  follow: var int, w: var BitWriter) =
  let span = uint64(high - low) + 1
  let oldLow = low
  high = oldLow + uint32(span * uint64(cum[symbol - 1]) div uint64(cum[0])) - 1
  low = oldLow + uint32(span * uint64(cum[symbol]) div uint64(cum[0]))
  while true:
    if high < 32768'u32:
      w.bitPlusFollow(0, follow)
    elif low >= 32768'u32:
      w.bitPlusFollow(1, follow)
      low -= 32768
      high -= 32768
    elif low >= 16384'u32 and high < 49152'u32:
      inc follow
      low -= 16384
      high -= 16384
    else:
      break
    low *= 2
    high = high * 2 + 1

proc updateModel(symbol: int, charToIndex: var array[256, int],
                 indexToChar: var array[258, uint8], freq: var array[258, int],
                 cum: var array[258, int]) =
  if cum[0] == 16383:
    var total = 0
    for i in countdown(Symbols, 0):
      freq[i] = (freq[i] + 1) div 2
      cum[i] = total
      total += freq[i]
  var i = symbol
  while freq[i] == freq[i - 1]: dec i
  if i < symbol:
    let oldI = indexToChar[i]
    let oldSymbol = indexToChar[symbol]
    indexToChar[i] = oldSymbol
    indexToChar[symbol] = oldI
    charToIndex[int(oldI)] = symbol
    charToIndex[int(oldSymbol)] = i
  inc freq[i]
  while i > 0:
    dec i
    inc cum[i]

proc arithmeticEncode(data: ptr UncheckedArray[uint8], count: int,
                      encoded: ptr UncheckedArray[uint8]): int =
  var charToIndex: array[256, int]
  var indexToChar: array[258, uint8]
  var freq: array[258, int]
  var cum: array[258, int]
  for i in 0 ..< 256:
    charToIndex[i] = i + 1
    indexToChar[i + 1] = uint8(i)
  for i in 0 .. Symbols:
    freq[i] = 1
    cum[i] = Symbols - i
  freq[0] = 0
  var w = BitWriter(bytes: encoded, length: 0, buffer: 0, bitsToGo: 8)
  var low = 0'u32
  var high = 65535'u32
  var follow = 0
  for i in 0 ..< count:
    let symbol = charToIndex[int(data[i])]
    encodeSymbol(symbol, cum, low, high, follow, w)
    updateModel(symbol, charToIndex, indexToChar, freq, cum)
  encodeSymbol(257, cum, low, high, follow, w)
  inc follow
  w.bitPlusFollow(if low < 16384'u32: 0 else: 1, follow)
  w.bytes[w.length] = uint8(w.buffer shr w.bitsToGo)
  inc w.length
  w.length

proc compressBounded(input: ptr UncheckedArray[uint8], n: int,
                     output: ptr UncheckedArray[uint8]): int =
  var order: array[MaxLength, int]
  var last: array[MaxLength, uint8]
  var rle: array[MaxLength * 2, uint8]
  var rleLength = 0
  for i in 0 ..< n: order[i] = i
  for i in 1 ..< n:
    let key = order[i]
    var j = i
    while j > 0 and rotationLess(input, n, key, order[j - 1]):
      order[j] = order[j - 1]
      dec j
    order[j] = key
  var primary = 0
  for row in 0 ..< n:
    if order[row] == 0: primary = row
    last[row] = input[(order[row] + n - 1) mod n]
  var i = 0
  while i < n:
    var count = 1
    let value = last[i]
    while i + count < n and last[i + count] == value and count < 127: inc count
    if count == 1:
      while i + count < n and last[i + count - 1] != last[i + count] and
            (i + count + 1 == n or last[i + count] != last[i + count + 1]):
        inc count
      rle[rleLength] = uint8(count and 0x7f); inc rleLength
      for j in 0 ..< count: rle[rleLength] = last[i + j]; inc rleLength
      i += count
    else:
      rle[rleLength] = uint8(count or 0x80); inc rleLength
      rle[rleLength] = value; inc rleLength
      i += count
  output[0] = uint8(n)
  output[1] = 0; output[2] = 0; output[3] = 0
  output[4] = uint8(primary)
  output[5] = 0; output[6] = 0; output[7] = 0
  8 + arithmeticEncode(addr rle[0], rleLength, addr output[8])

proc pcompress2*(values: ptr UncheckedArray[int64], length: csize_t,
                 output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
                 {.cdecl, exportc: "pcompress2".} =
  if values == nil or length < 2 or values[0] < 1 or values[0] > MaxLength: return -1
  let n = int(values[0])
  if length != csize_t(n + 1): return -1
  var input: array[MaxLength, uint8]
  for i in 0 ..< n:
    if values[i + 1] < 0 or values[i + 1] > 255: return -1
    input[i] = uint8(values[i + 1])
  var encoded: array[MaxOutput, uint8]
  let encodedLength = compressBounded(addr input[0], n, addr encoded[0])
  if output == nil or outputCapacity < csize_t(encodedLength): return -2
  for i in 0 ..< encodedLength: output[i] = encoded[i]
  int64(encodedLength)
