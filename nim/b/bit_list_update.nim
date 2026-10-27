const MaxN = 8
const MaxRequests = 32
const MaxInput = 50
const MaxOutputBytes = 392

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc bit_list_update*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "bit_list_update".} =
  if input.isNil or length < csize_t(4) or length > csize_t(MaxInput): return -1
  let nRaw = input[0]
  let requestsRaw = input[1]
  if nRaw < 1 or nRaw > MaxN or requestsRaw < 0 or requestsRaw > MaxRequests: return -1
  let n = int(nRaw)
  let requests = int(requestsRaw)
  if length != csize_t(2 + 2 * n + requests): return -1
  var order: array[MaxN, int]
  var seen: array[MaxN, bool]
  for i in 0 ..< n:
    let page = input[2 + i]
    if page < 0 or page >= nRaw or seen[int(page)]: return -1
    order[i] = int(page)
    seen[int(page)] = true
  var requestIds: array[MaxRequests, int]
  for i in 0 ..< requests:
    let page = input[2 + n + i]
    if page < 0 or page >= nRaw: return -1
    requestIds[i] = int(page)
  var bits: array[MaxN, int64]
  for i in 0 ..< n:
    let bit = input[2 + n + requests + i]
    if bit != 0 and bit != 1: return -1
    bits[i] = bit
  var positions: array[MaxRequests, int64]
  var totalCost = 0'i64
  for time in 0 ..< requests:
    let page = requestIds[time]
    var position = 0
    while position < n and order[position] != page: inc position
    if position == n: return -1
    positions[time] = int64(position + 1)
    totalCost += int64(position + 1)
    bits[page] = bits[page] xor 1
    if bits[page] == 1 and position > 0:
      for shift in countdown(position, 1): order[shift] = order[shift - 1]
      order[0] = page
  var words: array[1 + 2 * MaxN + MaxRequests, int64]
  words[0] = totalCost
  for i in 0 ..< n: words[1 + i] = int64(order[i])
  for i in 0 ..< requests: words[1 + n + i] = positions[i]
  for i in 0 ..< n: words[1 + n + requests + i] = bits[i]
  let outputBytes = csize_t(8 * (1 + 2 * n + requests))
  if output.isNil or capacity < outputBytes: return -2
  var staged: array[MaxOutputBytes, uint8]
  for word in 0 ..< 1 + 2 * n + requests: storeI64Le(addr staged[0], 8 * word, words[word])
  for byte in 0 ..< int(outputBytes): output[byte] = staged[byte]
  int64(outputBytes)
