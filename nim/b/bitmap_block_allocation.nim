const MaxBits = 4096
const MaxOps = 32
const MaxOutput = MaxBits div 8
proc bitmap_block_allocation*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "bitmap_block_allocation".} =
  if values == nil or length < 2 or length > csize_t(2 + 2*MaxOps): return -1
  let rawBits = values[0]; let rawOps = values[1]
  if rawBits < 1 or rawBits > MaxBits or rawOps < 0 or rawOps > MaxOps or length != csize_t(2 + 2*rawOps): return -1
  let bitCount = int(rawBits); let operationCount = int(rawOps)
  var offsets: array[MaxOps, int]
  var runs: array[MaxOps, int]
  for i in 0 ..< operationCount:
    let offset = values[2+2*i]; let run = values[3+2*i]
    if offset < 0 or offset > rawBits or run < 0 or run > rawBits-offset: return -1
    offsets[i] = int(offset); runs[i] = int(run)
  var bitmap: array[MaxBits, bool]
  for b in countup(0, bitCount - 1, 2): bitmap[b] = true
  for i in 0 ..< operationCount:
    for b in offsets[i] ..< offsets[i]+runs[i]:
      if i mod 3 == 0: bitmap[b] = true
      elif i mod 3 == 1: bitmap[b] = false
      else: bitmap[b] = not bitmap[b]
  let byteCount = (bitCount+7) div 8
  if output == nil or outputCapacity < csize_t(byteCount): return -2
  for j in 0 ..< byteCount:
    var packed = 0'u8
    for bit in 0 ..< 8:
      let index = j*8+bit
      if index < bitCount and bitmap[index]: packed = packed or (1'u8 shl bit)
    output[j] = packed
  int64(byteCount)
