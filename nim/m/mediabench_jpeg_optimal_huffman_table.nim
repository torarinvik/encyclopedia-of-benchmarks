const MaxSymbols = 20
const MaxCodeLength = 32
const MaxInputLength = 41

# Clean-room IJG JPEG 6a table-generation profile; see package LICENSE.txt.
proc mediabench_jpeg_optimal_huffman_table*(input: ptr UncheckedArray[int64], inputLength: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "mediabench_jpeg_optimal_huffman_table".} =
  if input == nil or inputLength < 3 or inputLength > MaxInputLength: return -1
  if input[0] < 1 or input[0] > MaxSymbols: return -1
  let count = int(input[0])
  if inputLength != csize_t(1 + 2 * count): return -1
  for i in 0..<count:
    let symbol = input[1 + 2 * i]
    let frequency = input[2 + 2 * i]
    if symbol < 0 or symbol > 255 or frequency < 1 or frequency > 1_000_000: return -1
    for j in 0..<i: if input[1 + 2 * j] == symbol: return -1
  let outputSize = 17 + count
  if output == nil or outputCapacity < csize_t(outputSize): return -2

  var freq: array[257, int64]
  var codeSize: array[257, int]
  var others: array[257, int]
  var bits: array[MaxCodeLength + 1, int]
  for i in 0..256: others[i] = -1
  for i in 0..<count: freq[int(input[1 + 2 * i])] = input[2 + 2 * i]
  freq[256] = 1
  while true:
    var c1 = -1
    var c2 = -1
    var value = 1_000_000_000'i64
    for i in 0..256:
      if freq[i] != 0 and freq[i] <= value:
        value = freq[i]
        c1 = i
    value = 1_000_000_000'i64
    for i in 0..256:
      if freq[i] != 0 and freq[i] <= value and i != c1:
        value = freq[i]
        c2 = i
    if c2 < 0: break
    freq[c1] += freq[c2]
    freq[c2] = 0
    inc codeSize[c1]
    var branch = c1
    while others[branch] >= 0:
      branch = others[branch]
      inc codeSize[branch]
    others[branch] = c2
    inc codeSize[c2]
    branch = c2
    while others[branch] >= 0:
      branch = others[branch]
      inc codeSize[branch]
  for i in 0..256:
    if codeSize[i] != 0:
      if codeSize[i] > MaxCodeLength: return -1
      inc bits[codeSize[i]]
  for i in countdown(MaxCodeLength, 17):
    while bits[i] > 0:
      var j = i - 2
      while j >= 0 and bits[j] == 0: dec j
      if j < 0 or bits[i] < 2: return -1
      bits[i] -= 2
      inc bits[i - 1]
      bits[j + 1] += 2
      dec bits[j]
  var longest = 16
  while longest > 0 and bits[longest] == 0: dec longest
  if longest == 0: return -1
  dec bits[longest]
  var symbolCount = 0
  for size in 1..MaxCodeLength:
    for symbol in 0..255:
      if codeSize[symbol] == size: inc symbolCount
  if symbolCount != count: return -1
  output[0] = uint8(count)
  for i in 1..16: output[i] = uint8(bits[i])
  var used = 17
  for size in 1..MaxCodeLength:
    for symbol in 0..255:
      if codeSize[symbol] == size:
        output[used] = uint8(symbol)
        inc used
  int64(used)
