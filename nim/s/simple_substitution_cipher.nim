proc simple_substitution_cipher*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "simple_substitution_cipher".} =
  if input.isNil or length < 28 or length > 284: return -1
  let mode = input[0]
  let n64 = input[27]
  if (mode != 0 and mode != 1) or n64 < 0 or n64 > 256 or int(length) != 28 + int(n64): return -1
  var seen: array[26, bool]
  for i in 0 ..< 26:
    let value = input[1 + i]
    if value < 65 or value > 90 or seen[int(value - 65)]: return -1
    seen[int(value - 65)] = true
  let n = int(n64)
  for i in 0 ..< n:
    if input[28 + i] < 0 or input[28 + i] > 127: return -1
  if output.isNil or outputCapacity < csize_t(n): return -2
  for i in 0 ..< n:
    let ch = input[28 + i]
    let lower = ch >= 97 and ch <= 122
    let upper = ch >= 65 and ch <= 90
    if not lower and not upper:
      output[i] = uint8(ch)
    else:
      let index = int(ch - (if lower: 97 else: 65))
      var mapped = index
      if mode == 0: mapped = int(input[1 + index] - 65)
      else:
        mapped = 0
        while mapped < 26 and input[1 + mapped] != 65 + index: inc mapped
      output[i] = uint8((if lower: 97 else: 65) + mapped)
  int64(n)
