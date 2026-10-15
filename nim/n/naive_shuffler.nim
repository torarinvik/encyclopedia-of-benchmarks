const MaxItems = 256
const RngModulus = 2_147_483_647'i64
const RngPeriod = RngModulus - 1

proc naive_shuffler*(input: ptr UncheckedArray[int64], length: csize_t,
                     output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "naive_shuffler".} =
  if input == nil or length < 2 or length > csize_t(MaxItems + 2): return -1
  if input[0] < 0 or input[0] >= RngPeriod or input[1] < 0 or input[1] > MaxItems: return -1
  let count = int(input[1])
  if int(length) != count + 2: return -1

  var items: array[MaxItems, uint8]
  for index in 0 ..< count:
    if input[index + 2] < 0 or input[index + 2] > 255: return -1
    items[index] = uint8(input[index + 2])
  if outputCapacity < csize_t(count) or (count > 0 and output == nil): return -2

  var state = input[0] + 1
  for index in 0 ..< count:
    let bound = int64(count)
    let limit = RngPeriod - RngPeriod mod bound
    var sample: int64
    while true:
      state = (state * 48_271) mod RngModulus
      sample = state - 1
      if sample < limit: break
    let other = int(sample mod bound)
    swap(items[index], items[other])
  for index in 0 ..< count:
    output[index] = items[index]
  int64(count)
