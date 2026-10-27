const MaxN = 8
const MaxRequests = 32
const MaxInput = 42
const MaxOutputBytes = 328

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc timestamp_list_update*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "timestamp_list_update".} =
  if input.isNil or length < csize_t(3) or length > csize_t(MaxInput): return -1
  let nRaw = input[0]
  let requestsRaw = input[1]
  if nRaw < 1 or nRaw > MaxN or requestsRaw < 0 or requestsRaw > MaxRequests: return -1
  let n = int(nRaw)
  let requests = int(requestsRaw)
  if length != csize_t(2 + n + requests): return -1
  var order: array[MaxN, int]
  var seen: array[MaxN, bool]
  for i in 0 ..< n:
    let item = input[2 + i]
    if item < 0 or item >= nRaw or seen[int(item)]: return -1
    order[i] = int(item)
    seen[int(item)] = true
  var requestIds: array[MaxRequests, int]
  for i in 0 ..< requests:
    let item = input[2 + n + i]
    if item < 0 or item >= nRaw: return -1
    requestIds[i] = int(item)
  var lastRequest: array[MaxN, int]
  for i in 0 ..< MaxN: lastRequest[i] = -1
  var positions: array[MaxRequests, int64]
  var totalCost = 0'i64
  for time in 0 ..< requests:
    let item = requestIds[time]
    var position = 0
    while position < n and order[position] != item: inc position
    if position == n: return -1
    positions[time] = int64(position + 1)
    totalCost += int64(position + 1)
    if lastRequest[item] >= 0:
      for target in 0 ..< position:
        let candidate = order[target]
        var occurrences = 0
        for t in (lastRequest[item] + 1) ..< time:
          if requestIds[t] == candidate: inc occurrences
        if occurrences <= 1:
          for shift in countdown(position, target + 1): order[shift] = order[shift - 1]
          order[target] = item
          break
    lastRequest[item] = time
  var words: array[1 + MaxN + MaxRequests, int64]
  words[0] = totalCost
  for i in 0 ..< n: words[1 + i] = int64(order[i])
  for i in 0 ..< requests: words[1 + n + i] = positions[i]
  let outputBytes = csize_t(8 * (1 + n + requests))
  if output.isNil or capacity < outputBytes: return -2
  var staged: array[MaxOutputBytes, uint8]
  for word in 0 ..< 1 + n + requests: storeI64Le(addr staged[0], 8 * word, words[word])
  for byte in 0 ..< int(outputBytes): output[byte] = staged[byte]
  int64(outputBytes)
