const MaxSteps = 8
const MaxInput = 18
const MaxOutput = 16
const MaxBid = 16

proc single_parameter_truthful_payment*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "single_parameter_truthful_payment".} =
  if values == nil or length < 4 or length > csize_t(MaxInput): return -1
  if values[0] < 0 or values[0] > MaxBid or values[1] < 1 or values[1] > MaxSteps: return -1
  let bid = int(values[0])
  let k = int(values[1])
  if int(length) != 2 + 2*k: return -1
  for i in 0 ..< k:
    let point = values[2+2*i]
    let load = values[3+2*i]
    if point < 0 or point >= MaxBid or load < 0 or load > MaxBid: return -1
    if (i == 0 and point != 0) or (i > 0 and (point <= values[2+2*(i-1)] or load > values[3+2*(i-1)])): return -1
  var allocation = 0'i64
  if bid < MaxBid:
    for i in 0 ..< k:
      if int(values[2+2*i]) <= bid: allocation = values[3+2*i]
  var area = 0'i64
  for i in 0 ..< k:
    let start = int(values[2+2*i])
    let finish = if i+1 < k: int(values[2+2*(i+1)]) else: MaxBid
    let left = max(start, bid)
    if finish > left: area += int64(finish-left) * values[3+2*i]
  let payment = int64(bid) * allocation + area
  if output == nil or capacity < csize_t(MaxOutput): return -2
  let allocBits = cast[uint64](allocation)
  let payBits = cast[uint64](payment)
  for b in 0 ..< 8:
    output[b] = uint8((allocBits shr (8*b)) and 255)
    output[8+b] = uint8((payBits shr (8*b)) and 255)
  int64(MaxOutput)
