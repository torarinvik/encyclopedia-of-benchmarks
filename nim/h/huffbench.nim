const
  MinPasses = 1'i64
  MaxPasses = 30'i64
  DataBytes = 4096
  OutputCapacity = 52

proc heapAdjust(frequency: array[512, uint], heap: var array[256, uint], active, oneBased: int) =
  var index = oneBased
  let value = heap[index - 1]
  while index <= active div 2:
    var child = index * 2
    if child < active and frequency[heap[child - 1]] > frequency[heap[child]]: inc child
    if frequency[value] < frequency[heap[child - 1]]: break
    heap[index - 1] = heap[child - 1]
    index = child
  heap[index - 1] = value

proc random4(seed: var int64): int =
  seed = seed xor 123459876'i64
  let quotient = seed div 127773
  seed = 16807 * (seed - quotient * 127773) - 2836 * quotient
  if seed < 0: seed += 2147483647
  result = int(seed mod 32)
  seed = seed xor 123459876'i64

proc compdecomp(data: var array[DataBytes, uint8]): tuple[compressedLength: int, checksum: uint32, valid: bool] =
  var frequency: array[512, uint]
  var heap: array[256, uint]
  var link: array[512, int]
  var code: array[256, uint32]
  var codeLength: array[256, uint8]
  for value in data: inc frequency[value]
  var active = 0
  for symbol in 0 ..< 256:
    if frequency[symbol] != 0:
      heap[active] = uint(symbol)
      inc active
  for index in countdown(active, 1): heapAdjust(frequency, heap, active, index)
  while active > 1:
    dec active
    let first = heap[0]
    heap[0] = heap[active]
    heapAdjust(frequency, heap, active, 1)
    let parent = 256 + active
    frequency[parent] = frequency[heap[0]] + frequency[first]
    link[first] = parent
    link[heap[0]] = -parent
    heap[0] = uint(parent)
    heapAdjust(frequency, heap, active, 1)
  link[256 + active] = 0
  for symbol in 0 ..< 256:
    if frequency[symbol] == 0: continue
    var depth = 0
    var bit = 1'u32
    var value = 0'u32
    var parent = link[symbol]
    while parent != 0:
      if parent < 0:
        value += bit
        parent = -parent
      parent = link[parent]
      bit = bit shl 1
      inc depth
    code[symbol] = value
    codeLength[symbol] = uint8(depth)

  var compressed: array[DataBytes + 1, uint8]
  var compressedUsed = 0
  var bout = 0'u8
  var bitIndex = -1
  for index in 0 ..< DataBytes:
    var mask = 1'u32 shl (int(codeLength[data[index]]) - 1)
    for _ in 0 ..< int(codeLength[data[index]]):
      if bitIndex == 7:
        compressed[compressedUsed] = bout
        inc compressedUsed
        bitIndex = 0
        bout = 0
      else:
        inc bitIndex
        bout = bout shl 1
      if (code[data[index]] and mask) != 0: bout = bout or 1
      mask = mask shr 1
  bout = bout shl (7 - bitIndex)
  compressed[compressedUsed] = bout
  inc compressedUsed

  var children: array[512, array[2, int]]
  var decodedSymbol: array[512, int]
  for node in 0 ..< 512:
    children[node][0] = -1
    children[node][1] = -1
    decodedSymbol[node] = -1
  var nodeCount = 1
  for symbol in 0 ..< 256:
    if frequency[symbol] == 0: continue
    var node = 0
    for bit in countdown(int(codeLength[symbol]) - 1, 0):
      let direction = int((code[symbol] shr bit) and 1)
      if children[node][direction] < 0:
        children[node][direction] = nodeCount
        inc nodeCount
      node = children[node][direction]
    decodedSymbol[node] = symbol
  var decoded = 0
  var sum = 0'u64
  var node = 0
  for index in 0 ..< compressedUsed:
    for bit in countdown(7, 0):
      if decoded >= DataBytes: break
      let direction = int((compressed[index] shr bit) and 1)
      node = children[node][direction]
      if node < 0: return (0, 0'u32, false)
      if decodedSymbol[node] >= 0:
        data[decoded] = uint8(decodedSymbol[node])
        sum += uint64(data[decoded])
        inc decoded
        node = 0
  if decoded != DataBytes: return (0, 0'u32, false)
  (compressedUsed, uint32(sum), true)

proc appendDecimal(staged: var array[OutputCapacity, uint8], usedInput: int, valueInput: uint32): int =
  var used = usedInput
  var value = valueInput
  var reversed: array[10, uint8]
  var digits = 0
  while true:
    reversed[digits] = uint8(48'u32 + value mod 10'u32)
    inc digits
    value = value div 10'u32
    if value == 0: break
  while digits > 0:
    dec digits
    staged[used] = reversed[digits]
    inc used
  used

proc formatOutput(passes: int64, compressedLength: int, checksum: uint32, staged: var array[OutputCapacity, uint8]): int =
  const prefix = "Huffbench passes="
  const middle = " compressed="
  const suffix = " checksum="
  var used = 0
  for ch in prefix: staged[used] = uint8(ord(ch)); inc used
  used = appendDecimal(staged, used, uint32(passes))
  for ch in middle: staged[used] = uint8(ord(ch)); inc used
  used = appendDecimal(staged, used, uint32(compressedLength))
  for ch in suffix: staged[used] = uint8(ord(ch)); inc used
  used = appendDecimal(staged, used, checksum)
  staged[used] = 10'u8
  inc used

proc coyote_huffbench*(passes: int64, output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64 {.cdecl, exportc: "coyote_huffbench".} =
  if passes < MinPasses or passes > MaxPasses: return -1
  if output.isNil: return -2
  const alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ012345"
  var data: array[DataBytes, uint8]
  var seed = 1325'i64
  for index in 0 ..< DataBytes: data[index] = uint8(ord(alphabet[random4(seed)]))
  var compressedLength = 0
  var checksum = 0'u32
  for _ in 0 ..< int(passes):
    let result = compdecomp(data)
    if not result.valid: return -1
    compressedLength = result.compressedLength
    checksum = result.checksum
  var staged: array[OutputCapacity, uint8]
  let used = formatOutput(passes, compressedLength, checksum, staged)
  if outputCapacity < csize_t(used): return -2
  for index in 0 ..< used: output[index] = staged[index]
  int64(used)
