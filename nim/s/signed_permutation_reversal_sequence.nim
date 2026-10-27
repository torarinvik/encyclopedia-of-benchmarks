const MaxN = 5
const MaxStates = 3840
const MaxMoves = 10
const MaxOutputBytes = 168

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc encode(permutation: array[MaxN, int64], n: int): int =
  var rank = 0
  var signs = 0
  for i in 0 ..< n:
    let value = int(if permutation[i] < 0: -permutation[i] else: permutation[i])
    var smaller = 0
    for j in i + 1 ..< n:
      let other = int(if permutation[j] < 0: -permutation[j] else: permutation[j])
      if other < value: inc smaller
    rank = rank * (n - i) + smaller
    if permutation[i] < 0: signs = signs or (1 shl (value - 1))
  rank * (1 shl n) + signs

proc decodeState(state, n: int, factorials: array[MaxN + 1, int],
                 permutation: var array[MaxN, int64]) =
  let signCount = 1 shl n
  var rank = state div signCount
  let signs = state mod signCount
  var available: array[MaxN, int]
  for i in 0 ..< n: available[i] = i + 1
  var remaining = n
  for i in 0 ..< n:
    let factor = factorials[n - i - 1]
    let digit = rank div factor
    rank = rank mod factor
    let value = available[digit]
    for j in digit ..< remaining - 1: available[j] = available[j + 1]
    dec remaining
    permutation[i] = if (signs and (1 shl (value - 1))) != 0: -int64(value) else: int64(value)

proc reverseSigned(permutation: var array[MaxN, int64], leftStart, rightStart: int) =
  var left = leftStart
  var right = rightStart
  while left < right:
    let a = permutation[left]
    let b = permutation[right]
    permutation[left] = -b
    permutation[right] = -a
    inc left
    dec right
  if left == right: permutation[left] = -permutation[left]

proc signed_permutation_reversal_sequence*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "signed_permutation_reversal_sequence".} =
  if input.isNil or length < csize_t(3) or length > csize_t(MaxN + 1): return -1
  let rawN = input[0]
  if rawN < 2 or rawN > int64(MaxN) or length != csize_t(rawN + 1): return -1
  let n = int(rawN)
  var seen = 0
  var permutation: array[MaxN, int64]
  for i in 0 ..< n:
    let value = input[i + 1]
    if value == 0 or value == low(int64): return -1
    let absolute = int(if value < 0: -value else: value)
    if absolute > n: return -1
    let bit = 1 shl (absolute - 1)
    if (seen and bit) != 0: return -1
    seen = seen or bit
    permutation[i] = value
  if seen != (1 shl n) - 1: return -1
  if output.isNil: return -2

  let factorials: array[MaxN + 1, int] = [1, 1, 2, 6, 24, 120]
  let stateCount = factorials[n] * (1 shl n)
  var parent: array[MaxStates, int32]
  var queue: array[MaxStates, int32]
  var moveLeft, moveRight: array[MaxStates, int8]
  for state in 0 ..< stateCount: parent[state] = -2
  let start = encode(permutation, n)
  var head = 0
  var tail = 0
  parent[start] = -1
  queue[tail] = int32(start)
  inc tail
  while head < tail and parent[0] == -2:
    let current = int(queue[head])
    inc head
    var currentPermutation: array[MaxN, int64]
    decodeState(current, n, factorials, currentPermutation)
    for left in 0 ..< n:
      if parent[0] != -2: break
      for right in left ..< n:
        var neighbor = currentPermutation
        reverseSigned(neighbor, left, right)
        let next = encode(neighbor, n)
        if parent[next] != -2: continue
        parent[next] = int32(current)
        moveLeft[next] = int8(left + 1)
        moveRight[next] = int8(right + 1)
        queue[tail] = int32(next)
        inc tail
        if next == 0: break
  if parent[0] == -2: return -1
  var reverseMoves: array[MaxMoves, array[2, int64]]
  var moveCount = 0
  var current = 0
  while parent[current] >= 0:
    if moveCount == MaxMoves: return -1
    reverseMoves[moveCount] = [int64(moveLeft[current]), int64(moveRight[current])]
    inc moveCount
    current = int(parent[current])
  let outputBytes = 8 * (1 + 2 * moveCount)
  if int(capacity) < outputBytes: return -2
  var staged: array[MaxOutputBytes, uint8]
  storeI64Le(addr staged[0], 0, int64(moveCount))
  for i in 0 ..< moveCount:
    let reverseIndex = moveCount - 1 - i
    storeI64Le(addr staged[0], 8 * (1 + 2 * i), reverseMoves[reverseIndex][0])
    storeI64Le(addr staged[0], 8 * (2 + 2 * i), reverseMoves[reverseIndex][1])
  for byte in 0 ..< outputBytes: output[byte] = staged[byte]
  int64(outputBytes)
