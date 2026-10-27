const MaxN = 32
const MaxInput = 35
const MaxOutput = 4096
const MaxResult = 512

proc emitBit(outp: ptr UncheckedArray[uint8], used: var int, value: bool) =
  outp[used] = if value: uint8(ord('1')) else: uint8(ord('0'))
  inc used
proc emitByte(outp: ptr UncheckedArray[uint8], used: var int, value: uint8) =
  outp[used] = value
  inc used
proc emitNumber(outp: ptr UncheckedArray[uint8], used: var int, value: uint64, width: int) =
  var shift = width - 1
  while shift >= 0:
    emitBit(outp, used, ((value shr shift) and 1'u64) != 0)
    dec shift
proc emitUnary(outp: ptr UncheckedArray[uint8], used: var int, value: uint64) =
  for i in 0'u64 ..< value: emitBit(outp, used, true)
  emitBit(outp, used, false)
proc floorLog2(value: uint64): int =
  var remaining = value
  result = -1
  while remaining != 0:
    inc result
    remaining = remaining shr 1
proc emitMinimal(outp: ptr UncheckedArray[uint8], used: var int, value, universe: uint64) =
  if universe == 1: return
  let lowWidth = floorLog2(universe)
  let shortCount = (1'u64 shl (lowWidth + 1)) - universe
  if value < shortCount: emitNumber(outp, used, value, lowWidth)
  else: emitNumber(outp, used, value + shortCount, lowWidth + 1)
proc emitGamma(outp: ptr UncheckedArray[uint8], used: var int, value: uint64) =
  let shifted = value + 1
  let width = floorLog2(shifted)
  emitUnary(outp, used, uint64(width))
  emitNumber(outp, used, shifted - (1'u64 shl width), width)
proc emitDelta(outp: ptr UncheckedArray[uint8], used: var int, value: uint64) =
  let shifted = value + 1
  let width = floorLog2(shifted)
  emitGamma(outp, used, uint64(width))
  emitNumber(outp, used, shifted - (1'u64 shl width), width)
proc emitInterpolative(outp: ptr UncheckedArray[uint8], used: var int,
                       input: ptr UncheckedArray[int64], left, right: int,
                       low, high: int64) =
  if left >= right: return
  let middle = left + (right - left - 1) div 2
  let value = input[3 + middle]
  let lower = low + int64(middle - left)
  let upper = high - int64(right - middle - 1)
  emitMinimal(outp, used, uint64(value - lower), uint64(upper - lower))
  emitInterpolative(outp, used, input, left, middle, low, value)
  emitInterpolative(outp, used, input, middle + 1, right, value + 1, high)
proc emitSimple9(outp: ptr UncheckedArray[uint8], used: var int,
                 input: ptr UncheckedArray[int64], n: int) =
  const slots = [28, 14, 9, 7, 5, 4, 3, 2, 1]
  const widths = [1, 2, 3, 4, 5, 7, 9, 14, 28]
  var position = 0
  while position < n:
    var selector = 0
    var take = 0
    var width = 0
    for s in 0..<9:
      let candidateCount = min(slots[s], n - position)
      var fits = true
      for j in 0..<candidateCount:
        if uint64(input[3 + position + j]) >= (1'u64 shl widths[s]): fits = false
      if fits:
        selector = s
        take = candidateCount
        width = widths[s]
        break
    var word = uint64(selector) shl 28
    for j in 0..<take:
      word = word or (uint64(input[3 + position + j]) shl (28 - width * (j + 1)))
    emitNumber(outp, used, word, 32)
    position += take

proc integer_sequence_codes*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "integer_sequence_codes".} =
  if input.isNil or length < 4 or length > MaxInput: return -1
  let mode0 = input[0]
  let n0 = input[1]
  let parameter = input[2]
  if mode0 < 0 or mode0 > 9 or n0 < 1 or n0 > MaxN or int(length) != int(n0) + 3: return -1
  let mode = int(mode0)
  let n = int(n0)
  if mode == 0:
    if parameter != 0: return -1
    for i in 0..<n: if input[3+i] < 0 or input[3+i] > 31: return -1
  elif mode == 1:
    if parameter < 2 or parameter > 1_000_000: return -1
    for i in 0..<n: if input[3+i] < 0 or input[3+i] >= parameter: return -1
  elif mode == 2 or mode == 3:
    if parameter != 0: return -1
    for i in 0..<n: if input[3+i] < 0 or input[3+i] > 1_000_000: return -1
  elif mode == 4:
    if parameter < 1 or parameter > 128: return -1
    for i in 0..<n: if input[3+i] < 0 or input[3+i] > 127: return -1
  elif mode == 7:
    if parameter != 0: return -1
    for i in 0..<n: if input[3+i] < 0 or input[3+i] > 1_000_000: return -1
  elif mode == 8:
    if parameter != 0: return -1
    for i in 0..<n: if input[3+i] < 0 or input[3+i] >= (1'i64 shl 28): return -1
  elif mode == 9:
    if parameter < 1 or parameter > 20: return -1
    for i in 0..<n: if input[3+i] < 0 or input[3+i] > 1_000_000: return -1
  else:
    if parameter < 2 or parameter > 4096 or n0 > parameter: return -1
    for i in 0..<n:
      if input[3+i] < 0 or input[3+i] >= parameter or (i > 0 and input[2+i] >= input[3+i]): return -1
  var staged: array[MaxOutput, uint8]
  var used = 0
  if mode == 0:
    for i in 0..<n: emitUnary(addr staged[0], used, uint64(input[3+i]))
  elif mode == 1:
    for i in 0..<n: emitMinimal(addr staged[0], used, uint64(input[3+i]), uint64(parameter))
  elif mode == 2:
    for i in 0..<n: emitGamma(addr staged[0], used, uint64(input[3+i]))
  elif mode == 3:
    for i in 0..<n: emitDelta(addr staged[0], used, uint64(input[3+i]))
  elif mode == 4:
    let b = uint64(parameter)
    for i in 0..<n:
      let x = uint64(input[3+i])
      emitUnary(addr staged[0], used, x div b)
      emitMinimal(addr staged[0], used, x mod b, b)
  elif mode == 5:
    var width = 0
    while uint64(n) * (1'u64 shl (width + 1)) <= uint64(parameter): inc width
    let bucketSize = 1'u64 shl width
    let buckets = int((uint64(parameter) + bucketSize - 1) div bucketSize)
    var counts: array[4096, uint8]
    for i in 0..<n: inc counts[int(uint64(input[3+i]) div bucketSize)]
    for bucket in 0..<buckets: emitUnary(addr staged[0], used, uint64(counts[bucket]))
    for i in 0..<n: emitNumber(addr staged[0], used, uint64(input[3+i]) mod bucketSize, width)
  elif mode == 6:
    emitInterpolative(addr staged[0], used, input, 0, n, 0, parameter)
  elif mode == 7:
    for i in 0..<n:
      let value = uint64(input[3+i])
      var highest = floorLog2(value)
      if highest < 0: highest = 0 else: highest = (highest div 7) * 7
      var shift = highest
      while shift >= 0:
        var byte = uint8((value shr shift) and 0x7f'u64)
        if shift != 0: byte = byte or 0x80'u8
        emitByte(addr staged[0], used, byte)
        shift -= 7
  elif mode == 8:
    emitSimple9(addr staged[0], used, input, n)
  else:
    let width = int(parameter)
    let lowMask = (1'u64 shl width) - 1
    var exceptionCount = 0
    for i in 0..<n:
      let value = uint64(input[3+i])
      emitNumber(addr staged[0], used, value and lowMask, width)
      if value >= (1'u64 shl width): inc exceptionCount
    emitNumber(addr staged[0], used, uint64(exceptionCount), 6)
    var positionWidth = 0
    while (1 shl positionWidth) < n: inc positionWidth
    for i in 0..<n:
      let value = uint64(input[3+i])
      if value >= (1'u64 shl width):
        emitNumber(addr staged[0], used, uint64(i), positionWidth)
        emitNumber(addr staged[0], used, value, 20)
  if output.isNil: return -2
  if mode == 7:
    if int(capacity) < used: return -2
    for i in 0..<used: output[i] = staged[i]
    return int64(used)
  let bytes = (used + 7) div 8
  if int(capacity) < bytes: return -2
  var packed: array[MaxResult, uint8]
  for i in 0..<used:
    if staged[i] == uint8(ord('1')):
      packed[i div 8] = packed[i div 8] or (1'u8 shl (7 - i mod 8))
  for i in 0..<bytes: output[i] = packed[i]
  int64(bytes)
