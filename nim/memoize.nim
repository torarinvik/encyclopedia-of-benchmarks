const MaxInputLength = 259
const MaxArity = 4
const MaxCalls = 64
const MaxOutputBytes = 520
const Base = 201'i64

proc putI64Le(output: var array[MaxOutputBytes, uint8], offset: int, value: int64) =
  let bits = uint64(value)
  for byteIndex in 0 ..< 8:
    output[offset + byteIndex] = uint8((bits shr (byteIndex * 8)) and 0xff'u64)

proc memoize*(input: ptr UncheckedArray[int64], inputLength: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "memoize".} =
  if input == nil or inputLength < 2 or inputLength > MaxInputLength.csize_t: return -1
  if input[0] < 0 or input[0] > MaxArity or input[1] < 0 or input[1] > MaxCalls: return -1
  let arity = int(input[0])
  let callCount = int(input[1])
  if inputLength != csize_t(2 + arity * callCount): return -1
  for index in 0 ..< arity * callCount:
    let value = input[csize_t(2 + index)]
    if value < -100 or value > 100: return -1

  var keys: array[MaxCalls, array[MaxArity, int64]]
  var keyResults: array[MaxCalls, int64]
  var keyCount = 0
  var results: array[MaxCalls + 1, int64]
  for callIndex in 0 ..< callCount:
    let start = 2 + callIndex * arity
    var key: array[MaxArity, int64]
    var encoded = 0'i64
    for argumentIndex in 0 ..< arity:
      let value = input[csize_t(start + argumentIndex)]
      key[argumentIndex] = value
      encoded = encoded * Base + value + 100
    var found = -1
    for previous in 0 ..< keyCount:
      var equal = true
      for argumentIndex in 0 ..< arity:
        if keys[previous][argumentIndex] != key[argumentIndex]: equal = false
      if equal:
        found = previous
        break
    if found >= 0:
      results[callIndex] = keyResults[found]
    else:
      keys[keyCount] = key
      keyResults[keyCount] = encoded
      keyCount += 1
      results[callIndex] = encoded
  results[callCount] = int64(keyCount)

  let outputBytes = 8 * (callCount + 1)
  var staged: array[MaxOutputBytes, uint8]
  for index in 0 .. callCount: putI64Le(staged, index * 8, results[index])
  if output == nil or capacity < csize_t(outputBytes): return -2
  for index in 0 ..< outputBytes: output[index] = staged[index]
  int64(outputBytes)
