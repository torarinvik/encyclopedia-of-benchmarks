const MaxNonterminals = 4
const MaxTerminals = 2
const MaxWordLength = 8
const MaxProductions = 12
const MaxInputLength = 62

proc cyk_context_free_recognition*(input: ptr UncheckedArray[int64],
    length: csize_t): int64 {.cdecl, exportc: "cyk_context_free_recognition".} =
  if input.isNil or length < csize_t(5) or length > csize_t(MaxInputLength): return -1
  let variablesValue = input[0]
  let alphabetValue = input[1]
  let wordValue = input[2]
  let ruleValue = input[3]
  let startValue = input[4]
  if variablesValue < 1'i64 or variablesValue > int64(MaxNonterminals) or
      alphabetValue < 1'i64 or alphabetValue > int64(MaxTerminals) or
      wordValue < 1'i64 or wordValue > int64(MaxWordLength) or
      ruleValue < 0'i64 or ruleValue > int64(MaxProductions) or
      startValue < 0'i64 or startValue >= variablesValue: return -1
  let wordLength = int(wordValue)
  let ruleCount = int(ruleValue)
  if length != csize_t(5 + wordLength + 4 * ruleCount): return -1
  for position in 0..<wordLength:
    let token = input[5 + position]
    if token < 0'i64 or token >= alphabetValue: return -1
  let rules = 5 + wordLength
  for rule in 0..<ruleCount:
    let offset = rules + 4 * rule
    let kind = input[offset]
    let lhs = input[offset + 1]
    let first = input[offset + 2]
    let second = input[offset + 3]
    if lhs < 0'i64 or lhs >= variablesValue: return -1
    if kind == 0'i64:
      if first < 0'i64 or first >= alphabetValue or second != 0'i64: return -1
    elif kind == 1'i64:
      if first < 0'i64 or first >= variablesValue or
          second < 0'i64 or second >= variablesValue: return -1
    else:
      return -1

  var chart: array[4, array[8, array[9, bool]]]
  for position in 0..<wordLength:
    let token = input[5 + position]
    for rule in 0..<ruleCount:
      let offset = rules + 4 * rule
      if input[offset] == 0'i64 and input[offset + 2] == token:
        chart[int(input[offset + 1])][position][1] = true
  for width in 2..wordLength:
    for left in 0..(wordLength - width):
      for rule in 0..<ruleCount:
        let offset = rules + 4 * rule
        if input[offset] != 1'i64: continue
        let lhs = int(input[offset + 1])
        let first = int(input[offset + 2])
        let second = int(input[offset + 3])
        for split in 1..<width:
          if chart[first][left][split] and chart[second][left + split][width - split]:
            chart[lhs][left][width] = true
            break
  if chart[int(startValue)][0][wordLength]: 1'i64 else: 0'i64
