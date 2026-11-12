const
  MaxCategories = 8
  MaxSamples = 8
  MaxAttempts = 32
  MaxInputValues = 83
  DrawScale = 4_294_967_296'u64

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255'u64)

proc discrete_rejection_sampling*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc:"discrete_rejection_sampling".} =
  if input.isNil or length < csize_t(3) or length > csize_t(MaxInputValues): return -1
  let nValue = input[0]
  let samplesValue = input[1]
  let attemptsValue = input[2]
  if nValue < 1 or nValue > MaxCategories or samplesValue < 1 or samplesValue > MaxSamples or
      attemptsValue < 1 or attemptsValue > MaxAttempts: return -1
  let n = int(nValue)
  let wanted = int(samplesValue)
  let attempts = int(attemptsValue)
  if int64(length) != int64(3 + 2 * n + 2 * attempts): return -1

  var target, proposal, cumulative: array[MaxCategories, uint64]
  var targetTotal = 0'u64
  var proposalTotal = 0'u64
  for i in 0 ..< n:
    let weight = input[3 + i]
    let qWeight = input[3 + n + i]
    if weight < 1 or weight > 20 or qWeight < 1 or qWeight > 20: return -1
    target[i] = uint64(weight)
    proposal[i] = uint64(qWeight)
    targetTotal += target[i]
    proposalTotal += proposal[i]
    cumulative[i] = proposalTotal

  var envelope = 1'u64
  for i in 0 ..< n:
    let numerator = target[i] * proposalTotal
    let denominator = targetTotal * proposal[i]
    let ratioCeiling = (numerator + denominator - 1) div denominator
    if ratioCeiling > envelope: envelope = ratioCeiling

  let tapeOffset = 3 + 2 * n
  for attempt in 0 ..< attempts:
    let proposalDraw = input[tapeOffset + 2 * attempt]
    let acceptanceDraw = input[tapeOffset + 2 * attempt + 1]
    if proposalDraw < 0 or uint64(proposalDraw) >= proposalTotal or
        acceptanceDraw < 0 or uint64(acceptanceDraw) >= DrawScale: return -1

  let outputBytes = 16 * wanted
  if output.isNil or capacity < csize_t(outputBytes): return -2
  var staged: array[2 * MaxSamples, int64]
  var produced = 0
  var attemptsSinceAcceptance = 0
  for attempt in 0 ..< attempts:
    inc attemptsSinceAcceptance
    let proposalDraw = uint64(input[tapeOffset + 2 * attempt])
    let acceptanceDraw = uint64(input[tapeOffset + 2 * attempt + 1])
    var category = 0
    while cumulative[category] <= proposalDraw: inc category
    let left = acceptanceDraw * targetTotal * proposal[category] * envelope
    let right = DrawScale * target[category] * proposalTotal
    if left < right:
      staged[produced] = int64(category)
      staged[produced + 1] = int64(attemptsSinceAcceptance)
      produced += 2
      attemptsSinceAcceptance = 0
      if produced == 2 * wanted: break
  if produced != 2 * wanted: return -3
  for i in 0 ..< produced: storeI64Le(output, 8 * i, staged[i])
  int64(outputBytes)
