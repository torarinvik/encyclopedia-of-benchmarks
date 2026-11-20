type I64Input = ptr UncheckedArray[int64]

const MaxText = 4096
const MaxPattern = 128
const MaxInput = 4227
const MaxStates = 2 * MaxPattern + 2

type SuffixAutomaton = object
  transition: array[MaxStates, array[4, int64]]
  suffixLink: array[MaxStates, int64]
  maxLength: array[MaxStates, int64]
  stateCount: int

proc initSam(sam: var SuffixAutomaton) =
  sam.stateCount = 1
  for state in 0 ..< MaxStates:
    sam.suffixLink[state] = -1
    sam.maxLength[state] = 0
    for symbol in 0 ..< 4:
      sam.transition[state][symbol] = -1

proc extend(sam: var SuffixAutomaton, last: int64, symbol: int): int64 =
  if sam.stateCount >= MaxStates: return -1
  let current = sam.stateCount
  inc sam.stateCount
  sam.maxLength[current] = sam.maxLength[int(last)] + 1
  var state = last
  while state >= 0 and sam.transition[int(state)][symbol] < 0:
    sam.transition[int(state)][symbol] = int64(current)
    state = sam.suffixLink[int(state)]
  if state < 0:
    sam.suffixLink[current] = 0
  else:
    let target = sam.transition[int(state)][symbol]
    if sam.maxLength[int(state)] + 1 == sam.maxLength[int(target)]:
      sam.suffixLink[current] = target
    else:
      if sam.stateCount >= MaxStates: return -1
      let clone = sam.stateCount
      inc sam.stateCount
      sam.transition[clone] = sam.transition[int(target)]
      sam.suffixLink[clone] = sam.suffixLink[int(target)]
      sam.maxLength[clone] = sam.maxLength[int(state)] + 1
      while state >= 0 and sam.transition[int(state)][symbol] == target:
        sam.transition[int(state)][symbol] = int64(clone)
        state = sam.suffixLink[int(state)]
      sam.suffixLink[int(target)] = int64(clone)
      sam.suffixLink[current] = int64(clone)
  int64(current)

proc search(sam: var SuffixAutomaton, input: I64Input, textOffset, n, m: int): int64 =
  var state = 0
  var matched = 0'i64
  var count = 0'i64
  var offsetSum = 0'i64
  var offsetXor = 0'i64
  for position in 0 ..< n:
    let symbol = int(input[textOffset + position])
    var target = sam.transition[state][symbol]
    if target >= 0:
      inc matched
      state = int(target)
    else:
      while state != 0 and sam.transition[state][symbol] < 0:
        state = int(sam.suffixLink[state])
      target = sam.transition[state][symbol]
      if target >= 0:
        matched = sam.maxLength[state] + 1
        state = int(target)
      else:
        matched = 0
        state = 0
    if matched == int64(m):
      let start = int64(position + 1 - m)
      inc count
      offsetSum += start
      offsetXor = offsetXor xor start
  (count shl 36) or (offsetSum shl 12) or offsetXor

proc forward_dawg_matching*(input: I64Input, length: csize_t): int64
    {.cdecl, exportc: "forward_dawg_matching".} =
  if input == nil or length < 2 or length > MaxInput: return -1
  let nValue = input[0]
  let mValue = input[1]
  if nValue < 0 or nValue > MaxText or mValue < 1 or mValue > MaxPattern: return -1
  let n = int(nValue)
  let m = int(mValue)
  if length != csize_t(2 + n + m): return -1
  for index in 0 ..< n + m:
    if input[2 + index] < 0 or input[2 + index] > 3: return -1
  var pattern: array[MaxPattern, int64]
  for index in 0 ..< m:
    pattern[index] = input[2 + n + index]
  var sam: SuffixAutomaton
  initSam(sam)
  var last = 0'i64
  for index in 0 ..< m:
    last = sam.extend(last, int(pattern[index]))
    if last < 0: return -1
  search(sam, input, 2, n, m)
