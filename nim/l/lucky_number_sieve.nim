type
  I64Input = ptr UncheckedArray[int64]
  U8Output = ptr UncheckedArray[uint8]

proc lucky_number_sieve*(input: I64Input, length: csize_t, output: U8Output,
    outputCapacity: csize_t): int64 {.cdecl, exportc: "lucky_number_sieve".} =
  const MaxCandidates = 2048
  if input == nil or length != 2: return -1
  let mode = input[0]
  let bound = input[1]
  if (mode != 0 and mode != 1) or bound < 0 or bound > 4096: return -1

  var candidates: array[MaxCandidates, int64]
  var count = 0
  let first = if mode == 0: 1'i64 else: 2'i64
  var value = first
  while value <= bound:
    candidates[count] = value
    inc count
    value += 2

  var selected = 1
  while selected < count:
    let step = int(candidates[selected])
    if step > count: break
    var write = 0
    var rank = 0
    for read in 0 ..< count:
      inc rank
      if rank mod step != 0:
        candidates[write] = candidates[read]
        inc write
    count = write
    inc selected

  let outputBytes = count * 8
  if output == nil or outputCapacity < csize_t(outputBytes): return -2
  for index in 0 ..< count:
    let bits = uint64(candidates[index])
    for byte in 0 ..< 8:
      output[index * 8 + byte] = uint8((bits shr (byte * 8)) and 255'u64)
  int64(outputBytes)
