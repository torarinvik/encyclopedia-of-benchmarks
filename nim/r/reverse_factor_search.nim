const MaxText = 4096
const MaxPattern = 128
const MaxInputLength = 4227
const MaxStates = 2 * MaxPattern + 1

proc reverse_factor_search*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "reverse_factor_search".} =
  if input == nil or length < 2 or length > csize_t(MaxInputLength): return -1
  let n64 = input[0]
  let m64 = input[1]
  if n64 < 0 or n64 > int64(MaxText) or m64 < 1 or m64 > int64(MaxPattern): return -1
  let n = int(n64)
  let m = int(m64)
  if length != csize_t(2 + n + m): return -1
  var text: array[MaxText, uint8]
  var pattern: array[MaxPattern, uint8]
  for q in 0 ..< n:
    let value = input[2 + q]
    if value < 0 or value > 3: return -1
    text[q] = uint8(value)
  for q in 0 ..< m:
    let value = input[2 + n + q]
    if value < 0 or value > 3: return -1
    pattern[q] = uint8(value)
  if n < m: return 0

  var transitions: array[MaxStates * 4, int]
  var suffixLink: array[MaxStates, int]
  var maxLength: array[MaxStates, int]
  var terminal: array[MaxStates, bool]
  for state in 0 ..< MaxStates:
    suffixLink[state] = -1
    for symbol in 0 ..< 4: transitions[state * 4 + symbol] = -1
  var stateCount = 1
  var last = 0
  for pos in 0 ..< m:
    let symbol = int(pattern[m - 1 - pos])
    let current = stateCount
    inc stateCount
    maxLength[current] = maxLength[last] + 1
    var predecessor = last
    while predecessor >= 0 and transitions[predecessor * 4 + symbol] < 0:
      transitions[predecessor * 4 + symbol] = current
      predecessor = suffixLink[predecessor]
    if predecessor < 0:
      suffixLink[current] = 0
    else:
      let target = transitions[predecessor * 4 + symbol]
      if maxLength[predecessor] + 1 == maxLength[target]:
        suffixLink[current] = target
      else:
        let clone = stateCount
        inc stateCount
        for symbolIndex in 0 ..< 4:
          transitions[clone * 4 + symbolIndex] = transitions[target * 4 + symbolIndex]
        maxLength[clone] = maxLength[predecessor] + 1
        suffixLink[clone] = suffixLink[target]
        while predecessor >= 0 and transitions[predecessor * 4 + symbol] == target:
          transitions[predecessor * 4 + symbol] = clone
          predecessor = suffixLink[predecessor]
        suffixLink[target] = clone
        suffixLink[current] = clone
    last = current
  var terminalState = last
  while terminalState >= 0:
    terminal[terminalState] = true
    terminalState = suffixLink[terminalState]

  var count = 0'i64
  var offsetSum = 0'i64
  var offsetXor = 0'i64
  var period = m
  var start = 0
  while start <= n - m:
    var index = m - 1
    var state = 0
    var shift = m
    while start + index >= 0:
      let target = transitions[state * 4 + int(text[start + index])]
      if target < 0: break
      state = target
      if terminal[state]:
        period = shift
        shift = index
      dec index
    if index < 0:
      inc count
      offsetSum += int64(start)
      offsetXor = offsetXor xor int64(start)
      shift = period
    start += shift
  (count shl 36) or (offsetSum shl 12) or offsetXor
