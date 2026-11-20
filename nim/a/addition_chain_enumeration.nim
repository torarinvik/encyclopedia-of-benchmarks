type
  I64Input = ptr UncheckedArray[int64]
  U8Output = ptr UncheckedArray[uint8]
  Search = object
    target: int
    limit: int
    chain: array[32, int]
    totalCount: int64
    brauerCount: int64

const MaxTarget = 31
const OutputBytes = 24

proc visit(state: var Search, length: int, prefixIsBrauer: bool) =
  let last = state.chain[length - 1]
  let steps = length - 1
  if last == state.target:
    if steps == state.limit:
      inc state.totalCount
      if prefixIsBrauer: inc state.brauerCount
    return
  let remaining = state.limit - steps
  if remaining <= 0 or last * (1 shl remaining) < state.target: return

  var generated: array[32, bool]
  for left in 0 ..< length:
    for right in left ..< length:
      let candidate = state.chain[left] + state.chain[right]
      if candidate <= last or candidate > state.target or generated[candidate]: continue
      generated[candidate] = true
      state.chain[length] = candidate
      var usesLast = false
      for index in 0 ..< length:
        if last + state.chain[index] == candidate: usesLast = true
      visit(state, length + 1, prefixIsBrauer and usesLast)

proc bitLength(valueInput: int): int =
  var value = valueInput
  while value != 0:
    inc result
    value = value shr 1

proc popcount(valueInput: int): int =
  var value = valueInput
  while value != 0:
    result += value and 1
    value = value shr 1

proc minimumCounts(target: int): array[3, int64] =
  if target == 1:
    result = [0'i64, 1'i64, 0'i64]
    return
  let lower = bitLength(target - 1)
  let upper = bitLength(target) - 1 + popcount(target) - 1
  for limit in lower .. upper:
    var state = Search(target: target, limit: limit)
    state.chain[0] = 1
    visit(state, 1, true)
    if state.totalCount != 0:
      result = [int64(limit), state.brauerCount, state.totalCount - state.brauerCount]
      return

proc storeI64Le(output: U8Output, offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[csize_t(offset + byte)] = uint8((bits shr (byte * 8)) and 255'u64)

proc addition_chain_enumeration*(input: I64Input, length: csize_t,
    output: U8Output, outputCapacity: csize_t): int64 {.cdecl, exportc: "addition_chain_enumeration".} =
  if input == nil or length != 1: return -1
  let targetValue = input[0]
  if targetValue < 1 or targetValue > MaxTarget: return -1
  let resultWords = minimumCounts(int(targetValue))
  if output == nil or outputCapacity < csize_t(OutputBytes): return -2
  for index in 0 ..< 3: storeI64Le(output, index * 8, resultWords[index])
  int64(OutputBytes)
