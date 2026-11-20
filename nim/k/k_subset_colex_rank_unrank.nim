const MaxN = 16
const MaxK = 16
const MaxParseableInputLength = 20

proc chooseSmall(n, kValue: int): int64 =
  if kValue > n: return 0
  var k = kValue
  if k > n - k: k = n - k
  var value = 1'i64
  for i in 1 .. k: value = value * int64(n - k + i) div int64(i)
  value

proc storeI64Le(output: ptr UncheckedArray[uint8], index: int, value: int64) =
  var bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[index * 8 + byte] = uint8(bits and 255'u64)
    bits = bits shr 8

proc k_subset_colex_rank_unrank*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc.} =
  if input.isNil or length < 1 or length > MaxParseableInputLength: return -1
  let mode = input[0]
  if (mode != 0 and mode != 1) or length < 3: return -1
  let rawN = input[1]
  let rawK = input[2]
  if rawN < 0 or rawN > MaxN or rawK < 0 or rawK > rawN: return -1
  let n = int(rawN)
  let k = int(rawK)
  var indices: array[MaxK, int64]
  var rank = 0'i64

  if mode == 0:
    if int(length) != 3 + k: return -1
    for i in 0 ..< k:
      let index = input[3 + i]
      if index < 0 or index >= rawN or (i > 0 and indices[i - 1] >= index): return -1
      indices[i] = index
      rank += chooseSmall(int(index), i + 1)
  else:
    if length != 4: return -1
    rank = input[3]
    if rank < 0 or rank >= chooseSmall(n, k): return -1
    var upper = n - 1
    var remaining = rank
    for order in countdown(k, 1):
      var candidate = upper
      while candidate >= 0 and chooseSmall(candidate, order) > remaining: dec candidate
      if candidate < 0: return -1
      indices[order - 1] = int64(candidate)
      remaining -= chooseSmall(candidate, order)
      upper = candidate - 1

  let needed = (k + 1) * 8
  if output.isNil or int(capacity) < needed: return -2
  storeI64Le(output, 0, rank)
  for i in 0 ..< k: storeI64Le(output, i + 1, indices[i])
  int64(needed)
