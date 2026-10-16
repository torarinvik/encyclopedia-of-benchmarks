const MaxN = 1_000_000_000_000_000'i64
const StateCapacity = 32_768
const JumpCapacity = 131_072
const TableMask = StateCapacity - 1

type
  State = object
    prefixSum: int32
    suffix: int64
    head: int32
  Jump = object
    difference: int64
    terms: int64
    k: int32
    next: int32
  Memo = object
    states: seq[State]
    jumps: seq[Jump]
    jumpCount: int
    failed: bool

proc newMemo(): Memo =
  result.states = newSeq[State](StateCapacity)
  result.jumps = newSeq[Jump](JumpCapacity)
  for state in result.states.mitems: state.head = -2

proc findState(memo: var Memo, prefixSum, suffix: int64): int =
  let slot = int((suffix mod StateCapacity.int64 + prefixSum * 1009) mod StateCapacity.int64)
  for probe in 0..<StateCapacity:
    let index = (slot + probe) and TableMask
    if memo.states[index].head == -2:
      memo.states[index] = State(prefixSum: prefixSum.int32, suffix: suffix, head: -1)
      return index
    if memo.states[index].prefixSum.int64 == prefixSum and memo.states[index].suffix == suffix:
      return index
  memo.failed = true
  -1

proc addJump(memo: var Memo, stateIndex: int, difference, terms, k: int64) =
  if memo.jumpCount >= JumpCapacity:
    memo.failed = true
    return
  let index = memo.jumpCount
  inc memo.jumpCount
  memo.jumps[index] = Jump(difference: difference, terms: terms, k: k.int32,
                           next: memo.states[stateIndex].head)
  memo.states[stateIndex].head = index.int32

proc power10(exponent: int64): int64 =
  result = 1
  for _ in 0..<exponent: result *= 10

proc digitSum(valueInput: int64): int64 =
  var value = valueInput
  while value > 0:
    result += value mod 10
    value = value div 10

proc compute(value: var int64, k, index, target: int64): tuple[difference, terms: int64] =
  let start = index
  let base = power10(k)
  let prefixSum = digitSum(value div base)
  var suffix = value mod base
  while result.terms + index < target:
    let addend = prefixSum + digitSum(suffix)
    result.difference += addend
    suffix += addend
    inc result.terms
    if suffix >= base: break
  value += result.difference

proc nextTerm(value: var int64, k, index, target: int64, memo: var Memo): tuple[difference, terms: int64] =
  let base = power10(k)
  let prefixSum = digitSum(value div base)
  let suffix = value mod base
  let maxTerms = target - index
  let stateIndex = findState(memo, prefixSum, suffix)
  if stateIndex < 0: return
  var best = -1
  var jump = memo.states[stateIndex].head.int
  while jump >= 0:
    let entry = memo.jumps[jump]
    if entry.k.int64 <= k and entry.terms <= maxTerms and
        (best < 0 or entry.terms > memo.jumps[best].terms):
      best = jump
    jump = entry.next.int
  if best >= 0:
    let entry = memo.jumps[best]
    result.difference = entry.difference
    result.terms = entry.terms
    value += result.difference
  if result.terms >= maxTerms or suffix + result.difference >= base: return
  if k > 2:
    while not memo.failed:
      let extra = nextTerm(value, k - 1, index + result.terms, target, memo)
      result.difference += extra.difference
      result.terms += extra.terms
      if result.terms >= maxTerms or suffix + result.difference >= base: break
  else:
    let extra = compute(value, k, index + result.terms, target)
    result.difference += extra.difference
    result.terms += extra.terms
  if not memo.failed and result.terms < maxTerms:
    addJump(memo, stateIndex, result.difference, result.terms, k)

proc problem551*(n: int64): int64 {.cdecl, exportc: "problem551".} =
  if n < 1 or n > MaxN: return -1
  var memo = newMemo()
  var value = 1'i64
  var jumped = 0'i64
  while jumped != n - 1 and not memo.failed:
    let step = nextTerm(value, 18, 1 + jumped, n, memo)
    jumped += step.terms
  if memo.failed: -1 else: value
