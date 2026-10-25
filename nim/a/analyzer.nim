const MaxEvents = 64
const MaxEpoch = 15
const MaxAddress = 255

proc analyzer*(input: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "analyzer".} =
  if input == nil or length < 1 or length > 194: return -1
  let countValue = input[0]
  if countValue < 0 or countValue > MaxEvents: return -1
  let count = int(countValue)
  if length != csize_t(1 + 3 * count): return -1
  var latestWriter: array[MaxAddress + 1, int64]
  for address in 0 .. MaxAddress: latestWriter[address] = -1
  var conflicts = 0'i64
  var previousEpoch = 0'i64
  for event in 0 ..< count:
    let base = 1 + 3 * event
    let epoch = input[base]
    let opcode = input[base + 1]
    let addressValue = input[base + 2]
    if epoch < previousEpoch or epoch < 0 or epoch > MaxEpoch
        or (opcode != 0 and opcode != 1) or addressValue < 0 or addressValue > MaxAddress: return -1
    previousEpoch = epoch
    let address = int(addressValue)
    if opcode == 0:
      latestWriter[address] = int64(event)
    else:
      for prior in 0 ..< event:
        let priorBase = 1 + 3 * prior
        if input[priorBase] < epoch and input[priorBase + 1] == 0
            and input[priorBase + 2] == addressValue and latestWriter[address] == int64(prior):
          inc conflicts
  conflicts
