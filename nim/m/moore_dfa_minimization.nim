const MAX_STATES = 8
const MAX_ALPHABET = 3

proc moore_dfa_minimization*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "moore_dfa_minimization".} =
  if input.isNil or length < 4 or length > 29:
    return -1
  let n64 = input[0]
  let alphabet64 = input[1]
  let start64 = input[2]
  let accepting = input[3]
  if n64 < 1 or n64 > 8 or alphabet64 < 1 or alphabet64 > 3:
    return -1
  if start64 < 0 or start64 >= n64 or accepting < 0 or accepting >= (1'i64 shl int(n64)):
    return -1
  let n = int(n64)
  let alphabet = int(alphabet64)
  if length != csize_t(4 + n * alphabet):
    return -1

  var transitions = newSeq[int](MAX_STATES * MAX_ALPHABET)
  for state in 0 ..< n:
    for symbol in 0 ..< alphabet:
      let target = input[4 + state * alphabet + symbol]
      if target < 0 or target >= n64:
        return -1
      transitions[state * MAX_ALPHABET + symbol] = int(target)

  var labels = newSeq[int](MAX_STATES)
  var refined = newSeq[int](MAX_STATES)
  var acceptanceId = @[-1, -1]
  var classes = 0
  for state in 0 ..< n:
    let bit = int((accepting shr state) and 1)
    if acceptanceId[bit] < 0:
      acceptanceId[bit] = classes
      inc classes
    labels[state] = acceptanceId[bit]

  var rounds = 0
  while true:
    var signatures = newSeq[int](MAX_STATES)
    var signatureCount = 0
    for state in 0 ..< n:
      var signature = labels[state]
      for symbol in 0 ..< alphabet:
        signature = signature * MAX_STATES + labels[transitions[state * MAX_ALPHABET + symbol]]
      var id = 0
      while id < signatureCount and signatures[id] != signature:
        inc id
      if id == signatureCount:
        signatures[signatureCount] = signature
        inc signatureCount
      refined[state] = id
    var changed = false
    for state in 0 ..< n:
      if refined[state] != labels[state]:
        changed = true
    if not changed:
      classes = signatureCount
      break
    for state in 0 ..< n:
      labels[state] = refined[state]
    classes = signatureCount
    inc rounds

  var packed = (int64(classes) shl 28) or (int64(rounds) shl 24)
  for state in 0 ..< n:
    packed = packed or (int64(labels[state]) shl (3 * state))
  packed
