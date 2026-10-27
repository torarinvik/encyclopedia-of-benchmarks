const MaxPattern = 6
const MaxVariables = 12
const MaxFactors = 8
const MaxText = 64
const MaxInput = 53
const MaxOutputBytes = 520

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc kmp_slp_jump_output*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "kmp_slp_jump_output".} =
  if input.isNil or length < csize_t(8) or length > csize_t(MaxInput): return -1
  var cursor = 0
  let patternRaw = input[cursor]
  inc cursor
  if patternRaw < 1 or patternRaw > MaxPattern: return -1
  let patternLength = int(patternRaw)
  var pattern: array[MaxPattern, int64]
  for i in 0 ..< patternLength:
    pattern[i] = input[cursor]
    inc cursor
    if pattern[i] < 0 or pattern[i] > 3: return -1
  if cursor >= int(length): return -1
  let variableRaw = input[cursor]
  inc cursor
  if variableRaw < 1 or variableRaw > MaxVariables or cursor + 3 * int(variableRaw) + 1 > int(length): return -1
  let variableCount = int(variableRaw)
  var kind: array[MaxVariables, int]
  var first: array[MaxVariables, int]
  var second: array[MaxVariables, int]
  var terminal: array[MaxVariables, int64]
  var variableLength: array[MaxVariables, int]
  for variable in 0 ..< variableCount:
    let kindRaw = input[cursor]
    let firstRaw = input[cursor + 1]
    let secondRaw = input[cursor + 2]
    cursor += 3
    if kindRaw == 0:
      if firstRaw < 0 or firstRaw > 3 or secondRaw != 0: return -1
      terminal[variable] = firstRaw
      variableLength[variable] = 1
    elif kindRaw == 1:
      if firstRaw < 0 or secondRaw < 0 or firstRaw >= variable or secondRaw >= variable: return -1
      kind[variable] = 1
      first[variable] = int(firstRaw)
      second[variable] = int(secondRaw)
      variableLength[variable] = variableLength[first[variable]] + variableLength[second[variable]]
      if variableLength[variable] > MaxText: return -1
    else:
      return -1
  if cursor >= int(length): return -1
  let factorRaw = input[cursor]
  inc cursor
  if factorRaw < 1 or factorRaw > MaxFactors or cursor + int(factorRaw) != int(length): return -1
  let factorCount = int(factorRaw)
  var factors: array[MaxFactors, int]
  var textLength = 0
  for i in 0 ..< factorCount:
    let factor = input[cursor]
    inc cursor
    if factor < 0 or factor >= variableRaw: return -1
    factors[i] = int(factor)
    textLength += variableLength[factors[i]]
    if textLength > MaxText: return -1

  var failure: array[MaxPattern, int]
  var border = 0
  for i in 1 ..< patternLength:
    while border > 0 and pattern[i] != pattern[border]: border = failure[border - 1]
    if pattern[i] == pattern[border]: inc border
    failure[i] = border
  var jump: array[MaxVariables, array[MaxPattern, int]]
  var outputMask: array[MaxVariables, array[MaxPattern, uint64]]
  for variable in 0 ..< variableCount:
    for state in 0 ..< patternLength:
      if kind[variable] == 0:
        var next = state
        while next > 0 and pattern[next] != terminal[variable]: next = failure[next - 1]
        if pattern[next] == terminal[variable]: inc next
        if next == patternLength:
          outputMask[variable][state] = 1'u64
          next = failure[patternLength - 1]
        jump[variable][state] = next
      else:
        let left = first[variable]
        let right = second[variable]
        let middle = jump[left][state]
        jump[variable][state] = jump[right][middle]
        outputMask[variable][state] = outputMask[left][state] or
          (outputMask[right][middle] shl variableLength[left])

  var state = 0
  var offset = 0
  var endOffsets = 0'u64
  for i in 0 ..< factorCount:
    let variable = factors[i]
    endOffsets = endOffsets or (outputMask[variable][state] shl offset)
    state = jump[variable][state]
    offset += variableLength[variable]
  var words: array[1 + MaxText, int64]
  var occurrences = 0
  for ending in 0 ..< textLength:
    if ((endOffsets shr ending) and 1'u64) != 0:
      if ending + 1 < patternLength: return -1
      words[1 + occurrences] = int64(ending + 1 - patternLength)
      inc occurrences
  words[0] = int64(occurrences)
  let outputBytes = csize_t(8 * (1 + occurrences))
  if output.isNil or capacity < outputBytes: return -2
  var staged: array[MaxOutputBytes, uint8]
  for word in 0 ..< 1 + occurrences: storeI64Le(addr staged[0], 8 * word, words[word])
  for byte in 0 ..< int(outputBytes): output[byte] = staged[byte]
  int64(outputBytes)
