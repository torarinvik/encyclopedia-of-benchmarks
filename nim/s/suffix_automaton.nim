const
  MaxText = 256
  MaxQueries = 128
  MaxStates = 2 * MaxText
  MaxInputLength = 33283
  MaxValidInputLength = 33282
  Alphabet = 128

type
  SamState = object
    length: int
    link: int32
    next: array[Alphabet, int32]

proc initializeState(state: var SamState) =
  state.length = 0
  state.link = -1
  for symbol in 0 ..< Alphabet:
    state.next[symbol] = -1

proc buildAutomaton(states: var array[MaxStates, SamState], text: openArray[int],
                    textLength: int): int =
  initializeState(states[0])
  var stateCount = 1
  var last = 0
  for position in 0 ..< textLength:
    let symbol = text[position]
    let current = stateCount
    inc stateCount
    initializeState(states[current])
    states[current].length = states[last].length + 1
    var previous = int32(last)
    while previous != -1 and states[int(previous)].next[symbol] == -1:
      states[int(previous)].next[symbol] = int32(current)
      previous = states[int(previous)].link
    if previous == -1:
      states[current].link = 0
    else:
      let nextState = int(states[int(previous)].next[symbol])
      if states[int(previous)].length + 1 == states[nextState].length:
        states[current].link = int32(nextState)
      else:
        let clone = stateCount
        inc stateCount
        states[clone] = states[nextState]
        states[clone].length = states[int(previous)].length + 1
        while previous != -1 and states[int(previous)].next[symbol] == int32(nextState):
          states[int(previous)].next[symbol] = int32(clone)
          previous = states[int(previous)].link
        states[nextState].link = int32(clone)
        states[current].link = int32(clone)
    last = current
  stateCount

proc findState(states: openArray[SamState], pattern: openArray[int], patternLength: int): int =
  var current = 0
  for position in 0 ..< patternLength:
    let nextState = states[current].next[pattern[position]]
    if nextState == -1: return -1
    current = int(nextState)
  current

proc countOccurrences(states: openArray[SamState], stateCount: int,
                      text: openArray[int], textLength: int,
                      pattern: openArray[int], patternLength: int): int64 =
  let patternState = findState(states, pattern, patternLength)
  if patternState < 0: return 0
  var occurrences: array[MaxStates, int64]
  var byLength: array[MaxText + 1, int]
  var order: array[MaxStates, int]
  for state in 0 ..< stateCount:
    inc byLength[states[state].length]
  for length in 1 .. textLength:
    byLength[length] += byLength[length - 1]
  for state in countdown(stateCount - 1, 0):
    let stateLength = states[state].length
    dec byLength[stateLength]
    order[byLength[stateLength]] = state
  var last = 0
  for position in 0 ..< textLength:
    last = int(states[last].next[text[position]])
    occurrences[last] = 1
  for index in countdown(stateCount - 1, 0):
    let state = order[index]
    let link = states[state].link
    if link != -1:
      occurrences[int(link)] += occurrences[state]
  occurrences[patternState]

proc countDistinctSubstrings(states: openArray[SamState], stateCount: int): int64 =
  var total = 0'i64
  for state in 1 ..< stateCount:
    total += int64(states[state].length - states[int(states[state].link)].length)
  total

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 0xff'u64)

proc suffix_automaton*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "suffix_automaton".} =
  if input.isNil or length < 2 or length > csize_t(MaxInputLength): return -1
  let inputLength = int(length)
  if input[0] < 1 or input[0] > int64(MaxText): return -1
  let textLength = int(input[0])
  let queryCountIndex = textLength + 1
  if inputLength <= queryCountIndex or input[queryCountIndex] < 0 or input[queryCountIndex] > int64(MaxQueries): return -1
  let queryCount = int(input[queryCountIndex])
  if inputLength > MaxValidInputLength: return -1
  var text: array[MaxText, int]
  for position in 0 ..< textLength:
    let symbol = input[position + 1]
    if symbol < 0 or symbol >= int64(Alphabet): return -1
    text[position] = int(symbol)
  var states: array[MaxStates, SamState]
  let stateCount = buildAutomaton(states, text, textLength)
  var results: array[MaxQueries, int64]
  var opcodes: array[MaxQueries, uint8]
  var cursor = queryCountIndex + 1
  for query in 0 ..< queryCount:
    if cursor + 1 >= inputLength: return -1
    let opcodeValue = input[cursor]
    inc cursor
    let patternLengthValue = input[cursor]
    inc cursor
    if opcodeValue < 0 or opcodeValue > 2 or patternLengthValue < 0 or patternLengthValue > int64(MaxText): return -1
    let opcode = int(opcodeValue)
    let patternLength = int(patternLengthValue)
    if opcode == 2 and patternLength != 0: return -1
    if patternLength > inputLength - cursor: return -1
    var pattern: array[MaxText, int]
    for position in 0 ..< patternLength:
      let symbol = input[cursor]
      inc cursor
      if symbol < 0 or symbol >= int64(Alphabet): return -1
      pattern[position] = int(symbol)
    opcodes[query] = uint8(opcode)
    case opcode
    of 0:
      results[query] = int64(ord(findState(states, pattern, patternLength) >= 0))
    of 1:
      results[query] = countOccurrences(states, stateCount, text, textLength, pattern, patternLength)
    else:
      results[query] = countDistinctSubstrings(states, stateCount)
  if cursor != inputLength: return -1
  let outputBytes = queryCount * 9
  if output.isNil or capacity < csize_t(outputBytes): return -2
  for query in 0 ..< queryCount:
    output[query * 9] = opcodes[query]
    storeI64Le(output, query * 9 + 1, results[query])
  int64(outputBytes)
