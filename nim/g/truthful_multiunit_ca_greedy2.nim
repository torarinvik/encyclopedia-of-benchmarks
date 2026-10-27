import math

const MaxItems = 6
const MaxBidders = 12
const MaxInput = 32
const MaxOutput = 104

proc putI64(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for b in 0 ..< 8: output[offset+b] = uint8((bits shr (8*b)) and 255)

proc truthful_multiunit_ca_greedy2*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "truthful_multiunit_ca_greedy2".} =
  if values == nil or length < 5 or length > csize_t(MaxInput): return -1
  if values[0] < 2 or values[0] > MaxItems or values[1] < 1 or values[1] > MaxBidders: return -1
  let items = int(values[0]); let bidders = int(values[1])
  if int(length) != 2+items+2*bidders: return -1
  var caps: array[MaxItems,int]
  var prices: array[MaxItems,float64]
  var minimum = 9
  for e in 0 ..< items:
    if values[2+e] < 1 or values[2+e] > 8: return -1
    caps[e] = int(values[2+e]); minimum = min(minimum,caps[e]); prices[e] = 1.0/float64(caps[e])
  var bids: array[MaxBidders,int]
  var masks: array[MaxBidders,int]
  for i in 0 ..< bidders:
    let value = values[2+items+2*i]; let mask = values[3+items+2*i]
    if value < 1 or value > 100 or mask < 1 or mask >= (1'i64 shl items): return -1
    bids[i] = int(value); masks[i] = int(mask)
  let threshold = pow(2.718281828459045,float64(minimum))*float64(items)
  var chosen: array[MaxBidders,bool]
  var order: array[MaxBidders,int]
  var count = 0
  while count < bidders:
    var best = -1; var bestScore = -1.0
    for i in 0 ..< bidders:
      if not chosen[i]:
        var denominator = 0.0
        for e in 0 ..< items:
          if (masks[i] and (1 shl e)) != 0: denominator += prices[e]
        let score = float64(bids[i])/denominator
        if best < 0 or score > bestScore: best = i; bestScore = score
    if best < 0: break
    chosen[best] = true; order[count] = best; inc count
    for e in 0 ..< items:
      if (masks[best] and (1 shl e)) != 0: prices[e] *= pow(threshold,1.0/float64(caps[e]))
    var dual = 0.0
    for e in 0 ..< items: dual += float64(caps[e])*prices[e]
    if dual >= threshold: break
  let bytes = 8*(1+count)
  if output == nil or int(capacity) < bytes: return -2
  var staged: array[MaxOutput,uint8]
  putI64(addr staged[0],0,int64(count))
  for i in 0 ..< count: putI64(addr staged[0],8*(i+1),int64(order[i]))
  for i in 0 ..< bytes: output[i] = staged[i]
  int64(bytes)
