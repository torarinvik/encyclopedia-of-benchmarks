const
  MinStrings = 2
  MaxStrings = 8
  MaxTotalSymbols = 24
  MaxTrieNodes = MaxTotalSymbols + 1
  MaxStates = 49
  AlphabetSize = 4
  MaxParseableLength = 34

type
  GsaState = object
    length: int
    link: int
    next: array[AlphabetSize, int]

proc generalized_suffix_automaton_union*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "generalized_suffix_automaton_union".} =
  if input == nil or length < 1 or length > MaxParseableLength: return -1
  if input[0] < MinStrings or input[0] > MaxStrings: return -1
  let stringCount = int(input[0])

  var states: array[MaxStates, GsaState]
  for state in 0 ..< MaxStates:
    states[state].link = -1
  var trieNext: array[MaxTrieNodes, array[AlphabetSize, int]]
  var trieParent: array[MaxTrieNodes, int]
  var trieSymbol: array[MaxTrieNodes, int]

  var trieNodeCount = 1
  var totalSymbols = 0
  var cursor = 1
  for _ in 0 ..< stringCount:
    if cursor >= int(length): return -1
    let stringLengthValue = input[cursor]
    inc cursor
    if stringLengthValue < 0 or stringLengthValue > 8: return -1
    let stringLength = int(stringLengthValue)
    if totalSymbols + stringLength > MaxTotalSymbols or stringLength > int(length) - cursor:
      return -1
    totalSymbols += stringLength

    var node = 0
    for offset in 0 ..< stringLength:
      let symbolValue = input[cursor + offset]
      if symbolValue < 0 or symbolValue >= AlphabetSize: return -1
      let symbol = int(symbolValue)
      var child = trieNext[node][symbol]
      if child == 0:
        if trieNodeCount >= MaxTrieNodes: return -1
        child = trieNodeCount
        inc trieNodeCount
        trieNext[node][symbol] = child
        states[node].next[symbol] = child
        trieParent[child] = node
        trieSymbol[child] = symbol
      node = child
    cursor += stringLength
  if cursor != int(length): return -1

  var stateCount = trieNodeCount
  var queue: array[MaxTrieNodes, int]
  var queueHead = 0
  var queueTail = 0
  for symbol in 0 ..< AlphabetSize:
    let child = trieNext[0][symbol]
    if child != 0:
      queue[queueTail] = child
      inc queueTail

  while queueHead < queueTail:
    let current = queue[queueHead]
    inc queueHead
    let parent = trieParent[current]
    let symbol = trieSymbol[current]
    states[current].length = states[parent].length + 1

    var previous = states[parent].link
    while previous != -1 and states[previous].next[symbol] == 0:
      states[previous].next[symbol] = current
      previous = states[previous].link
    if previous == -1:
      states[current].link = 0
    else:
      let nextState = states[previous].next[symbol]
      if states[previous].length + 1 == states[nextState].length:
        states[current].link = nextState
      else:
        if stateCount >= MaxStates: return -1
        let clone = stateCount
        inc stateCount
        states[clone].length = states[previous].length + 1
        states[clone].link = states[nextState].link
        for character in 0 ..< AlphabetSize:
          let destination = states[nextState].next[character]
          if destination != 0 and states[destination].length > 0:
            states[clone].next[character] = destination
        while previous != -1 and states[previous].next[symbol] == nextState:
          states[previous].next[symbol] = clone
          previous = states[previous].link
        states[nextState].link = clone
        states[current].link = clone

    for character in 0 ..< AlphabetSize:
      let child = trieNext[current][character]
      if child != 0:
        queue[queueTail] = child
        inc queueTail

  var distinctCount = 0'i64
  for state in 1 ..< stateCount:
    distinctCount += int64(states[state].length - states[states[state].link].length)
  return distinctCount
