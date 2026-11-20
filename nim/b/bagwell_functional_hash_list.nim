const Starts = [0, 8, 24]
const Sides = [8, 16, 32]
const MaxInput = 131

proc putWord(output: ptr UncheckedArray[uint8], at: int, value: int64) =
  let bits = cast[uint64](value)
  for b in 0..<8: output[at + b] = uint8((bits shr (8 * b)) and 255'u64)

proc bagwell_functional_hash_list*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "bagwell_functional_hash_list".} =
  if input.isNil or length < 2 or length > csize_t(MaxInput): return -1
  let nv = input[0]
  if nv < 0 or nv > 32: return -1
  let n = int(nv)
  let qAt = 1 + 2 * n
  if qAt >= int(length): return -1
  let qv = input[qAt]
  if qv < 1 or qv > 32: return -1
  let q = int(qv)
  let queryAt = qAt + 1
  if int(length) != 2 + 2 * n + 2 * q: return -1
  for i in 0..<n:
    if input[1+2*i] < int64(low(int32)) or input[1+2*i] > int64(high(int32)) or
       input[2+2*i] < int64(low(int32)) or input[2+2*i] > int64(high(int32)): return -1
  for j in 0..<q:
    let root = input[queryAt+2*j]
    let key = input[queryAt+2*j+1]
    if root < 0 or root > nv or key < int64(low(int32)) or key > int64(high(int32)): return -1
  let outputBytes = 8 * q
  if output.isNil or capacity < csize_t(outputBytes): return -2

  var keys: array[56, int64]
  var values: array[56, int64]
  var next: array[56, int]
  var heads: array[56, int]
  var prev: array[3, int]
  var rootBlock: array[33, int]
  var rootOffset: array[33, int]
  for i in 0..<56:
    next[i] = -1
    heads[i] = -1
  for i in 0..<3: prev[i] = -1
  for i in 0..<33:
    rootBlock[i] = -1
    rootOffset[i] = -1
  var current = 0
  for i in 0..<n:
    if i == 8 or i == 24:
      prev[current+1] = current
      inc current
    let offset = i - Starts[current]
    let slot = Starts[current] + offset
    let hash = cast[uint32](input[1+2*i])
    let bucketSlot = Starts[current] + int(hash and uint32(Sides[current]-1))
    keys[slot] = input[1+2*i]
    values[slot] = input[2+2*i]
    next[slot] = heads[bucketSlot]
    heads[bucketSlot] = offset
    rootBlock[i+1] = current
    rootOffset[i+1] = offset
  for j in 0..<q:
    let root = int(input[queryAt+2*j])
    let key = input[queryAt+2*j+1]
    var block = rootBlock[root]
    let limit = rootOffset[root]
    var answer = low(int64)
    if block >= 0:
      let hash = cast[uint32](key)
      var first = true
      while block >= 0 and answer == low(int64):
        let bucketSlot = Starts[block] + int(hash and uint32(Sides[block]-1))
        var chain = heads[bucketSlot]
        while chain >= 0:
          let entry = Starts[block] + chain
          if (not first or chain <= limit) and keys[entry] == key:
            answer = values[entry]
            break
          chain = next[entry]
        block = prev[block]
        first = false
    putWord(output, 8*j, answer)
  int64(outputBytes)
