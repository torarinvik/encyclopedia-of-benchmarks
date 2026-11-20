type I64Input = ptr UncheckedArray[int64]

const MaxText = 4096
const MaxPattern = 128
const MaxInput = 4227
const MaxStates = 2 * MaxPattern + 2
const Root = 0
const Artificial = 1

type Automaton = object
  transition: array[MaxStates, array[4, int64]]
  displacement: array[MaxStates, array[4, int64]]
  suffixLink: array[MaxStates, int64]
  maxLength: array[MaxStates, int64]
  position: array[MaxStates, int64]
  terminal: array[MaxStates, int64]
  stateCount: int

proc init(aut: var Automaton) =
  aut.stateCount = 2
  for state in 0 ..< MaxStates:
    aut.suffixLink[state] = -1
    aut.maxLength[state] = 0
    aut.position[state] = 0
    aut.terminal[state] = 0
    for symbol in 0 ..< 4:
      aut.transition[state][symbol] = -1
      aut.displacement[state][symbol] = 0
  aut.suffixLink[Root] = Artificial

proc build(aut: var Automaton, pattern: array[MaxPattern, int64], m: int): bool =
  var last = Root
  for offset in 0 ..< m:
    let symbol = int(pattern[m - 1 - offset])
    if aut.stateCount >= MaxStates: return false
    let current = aut.stateCount
    inc aut.stateCount
    aut.maxLength[current] = aut.maxLength[last] + 1
    aut.position[current] = aut.position[last] + 1
    var state = last
    while state != Root and aut.transition[state][symbol] < 0:
      aut.transition[state][symbol] = int64(current)
      aut.displacement[state][symbol] =
        aut.position[current] - aut.position[state] - 1
      state = int(aut.suffixLink[state])
    let target = aut.transition[state][symbol]
    if target < 0:
      aut.transition[Root][symbol] = int64(current)
      aut.displacement[Root][symbol] =
        aut.position[current] - aut.position[Root] - 1
      aut.suffixLink[current] = Root
    elif aut.maxLength[state] + 1 == aut.maxLength[int(target)]:
      aut.suffixLink[current] = target
    else:
      if aut.stateCount >= MaxStates: return false
      let clone = aut.stateCount
      inc aut.stateCount
      aut.transition[clone] = aut.transition[int(target)]
      aut.displacement[clone] = aut.displacement[int(target)]
      aut.suffixLink[clone] = aut.suffixLink[int(target)]
      aut.maxLength[clone] = aut.maxLength[state] + 1
      aut.position[clone] = aut.position[int(target)]
      aut.terminal[clone] = aut.terminal[int(target)]
      aut.suffixLink[int(target)] = int64(clone)
      aut.suffixLink[current] = int64(clone)
      while state != Artificial:
        let oldTarget = aut.transition[state][symbol]
        if oldTarget < 0 or aut.maxLength[int(oldTarget)] < aut.maxLength[clone]: break
        aut.displacement[state][symbol] =
          aut.position[int(oldTarget)] - aut.position[state] - 1
        aut.transition[state][symbol] = int64(clone)
        state = int(aut.suffixLink[state])
    last = current
  aut.terminal[last] = 1
  while last != Root:
    last = int(aut.suffixLink[last])
    aut.terminal[last] = 1
  true

proc mpNext(pattern: array[MaxPattern, int64], m: int,
            next: var array[MaxPattern + 1, int64]) =
  var i = 0'i64
  var border = -1'i64
  next[0] = -1
  while int(i) < m:
    while border >= 0 and pattern[int(i)] != pattern[int(border)]:
      border = next[int(border)]
    inc i
    inc border
    next[int(i)] = border

proc search(aut: Automaton, input: I64Input, n, m: int,
            mp: array[MaxPattern + 1, int64]): int64 =
  if n < m: return 0
  let period = int64(m) - mp[m]
  var count = 0'i64
  var offsetSum = 0'i64
  var offsetXor = 0'i64
  var start = 0
  var precedingShift = int64(m)
  while start <= n - m:
    var index = int64(m) - 1
    var state = Root
    var boundary = int64(m) - 1 - precedingShift
    let prefixLength = int64(m) - precedingShift
    let prefixPeriod = if precedingShift != int64(m):
      prefixLength - mp[int(prefixLength)]
    else: 0'i64
    var shift = int64(m)
    var displacementSum = 0'i64
    while index > boundary:
      let symbol = int(input[2 + start + int(index)])
      let target = aut.transition[state][symbol]
      if target < 0: break
      displacementSum += aut.displacement[state][symbol]
      state = int(target)
      if aut.terminal[state] != 0: shift = index
      dec index
    if index <= boundary:
      if displacementSum == 0:
        inc count
        offsetSum += int64(start)
        offsetXor = offsetXor xor int64(start)
        shift = period
      else:
        let half = (boundary + 1) div 2
        if prefixPeriod <= half:
          boundary -= prefixPeriod
          while index > boundary:
            let symbol = int(input[2 + start + int(index)])
            let target = aut.transition[state][symbol]
            if target < 0: break
            displacementSum += aut.displacement[state][symbol]
            state = int(target)
            if aut.terminal[state] != 0: shift = index
            dec index
          if index <= boundary: shift = displacementSum
        else:
          boundary = boundary - half - 1
          while index > boundary:
            let symbol = int(input[2 + start + int(index)])
            let target = aut.transition[state][symbol]
            if target < 0: break
            displacementSum += aut.displacement[state][symbol]
            state = int(target)
            if aut.terminal[state] != 0: shift = index
            dec index
    if shift <= 0: return -1
    start += int(shift)
    precedingShift = shift
  (count shl 36) or (offsetSum shl 12) or offsetXor

proc turbo_reverse_factor_search*(input: I64Input, length: csize_t): int64
    {.cdecl, exportc: "turbo_reverse_factor_search".} =
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
  for index in 0 ..< m: pattern[index] = input[2 + n + index]
  var aut: Automaton
  init(aut)
  if not build(aut, pattern, m): return -1
  var mp: array[MaxPattern + 1, int64]
  mpNext(pattern, m, mp)
  search(aut, input, n, m, mp)
