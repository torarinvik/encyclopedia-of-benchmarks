const
  MaxN = 64
  MaxParseableInputLength = 67
  MaxOutputBytes = 520
  I32Min = -2_147_483_648'i64
  I32Max = 2_147_483_647'i64
  Mbig = 2_147_483_647'i64

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (byte * 8)) and 255'u64)

proc linqshuffler*(input: ptr UncheckedArray[int64], inputLength: csize_t,
                   output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "linqshuffler".} =
  if input == nil or inputLength < 2 or inputLength > csize_t(MaxParseableInputLength): return -1
  let nValue = input[0]
  let seed = input[1]
  if nValue < 0 or nValue > MaxN or seed < I32Min or seed > I32Max: return -1
  let n = int(nValue)
  if int(inputLength) != n + 2: return -1

  var values: array[MaxN, int64]
  var keys: array[MaxN, int64]
  for index in 0 ..< n:
    let value = input[index + 2]
    if value < I32Min or value > I32Max: return -1
    values[index] = value

  let subtraction = if seed == I32Min: I32Max else: abs(seed)
  var seedArray: array[56, int64]
  var mj = 161_803_398'i64 - subtraction
  seedArray[55] = mj
  var mk = 1'i64
  for i in 1 ..< 55:
    let ii = (21 * i) mod 55
    seedArray[ii] = mk
    mk = mj - mk
    if mk < 0: mk += Mbig
    mj = seedArray[ii]
  for pass in 0 ..< 4:
    for i in 1 ..< 56:
      let offsetIndex = 1 + ((i + 30) mod 55)
      seedArray[i] -= seedArray[offsetIndex]
      if seedArray[i] < 0: seedArray[i] += Mbig

  var inext = 0
  var inextp = 21
  for index in 0 ..< n:
    inc inext
    if inext >= 56: inext = 1
    inc inextp
    if inextp >= 56: inextp = 1
    var sample = seedArray[inext] - seedArray[inextp]
    if sample == Mbig: dec sample
    if sample < 0: sample += Mbig
    seedArray[inext] = sample
    keys[index] = sample

  # Strict comparison preserves input order for equal random keys.
  var index = 1
  while index < n:
    let key = keys[index]
    let value = values[index]
    var cursor = index
    while cursor > 0 and keys[cursor - 1] > key:
      keys[cursor] = keys[cursor - 1]
      values[cursor] = values[cursor - 1]
      dec cursor
    keys[cursor] = key
    values[cursor] = value
    inc index

  let outputBytes = 8 * (n + 1)
  if outputBytes > MaxOutputBytes or output == nil or outputCapacity < csize_t(outputBytes): return -2
  storeI64Le(output, 0, nValue)
  for index in 0 ..< n:
    storeI64Le(output, 8 * (index + 1), values[index])
  int64(outputBytes)
