const MaxProcesses = 16
const MaxParseableInputLength = 51
const MaxOutputBytes = 384
const JavaMultiplier = 0x5DEECE66D'u64
const JavaAddend = 0xB'u64
const JavaMask = (1'u64 shl 48) - 1
const Int32MaxValue = 0x7FFF_FFFF'u64

proc nextJavaState(state: uint64): uint64 =
  let low = state and 0xFF_FFFF'u64
  let high = state shr 24
  let lowProduct = low * JavaMultiplier
  let highProduct = (high * JavaMultiplier) and 0xFF_FFFF'u64
  (lowProduct + (highProduct shl 24) + JavaAddend) and JavaMask

proc javaNextInt(state: var uint64, bound: uint64): uint64 =
  if (bound and (bound - 1)) == 0:
    state = nextJavaState(state)
    return (bound * (state shr 17)) shr 31
  while true:
    state = nextJavaState(state)
    let bits = state shr 17
    let value = bits mod bound
    if bits - value + (bound - 1) <= Int32MaxValue: return value

proc lottery_scheduling*(input: ptr UncheckedArray[int64], inputLength: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "lottery_scheduling".} =
  if input == nil or inputLength < 2 or inputLength > MaxParseableInputLength.csize_t: return -1
  if input[1] < 0 or input[1] > MaxProcesses: return -1
  let processCount = int(input[1])
  if int(inputLength) != 2 + 3 * processCount: return -1

  var processIds: array[MaxProcesses, int64]
  var burstTimes: array[MaxProcesses, int64]
  var ticketCounts: array[MaxProcesses, int64]
  var totalTickets = 0'i64
  var totalBurstTime = 0'i64
  for index in 0 ..< processCount:
    let processId = input[2 + 3 * index]
    let burstTime = input[3 + 3 * index]
    let tickets = input[4 + 3 * index]
    if processId < 0 or processId > 32767 or burstTime < 1 or burstTime > 1000 or
        tickets < 1 or tickets > 1000: return -1
    for prior in 0 ..< index:
      if processIds[prior] == processId: return -1
    processIds[index] = processId
    burstTimes[index] = burstTime
    ticketCounts[index] = tickets
    totalTickets += tickets
    totalBurstTime += burstTime
  if totalTickets > 16000 or totalBurstTime > 16000: return -1

  var randomState = (cast[uint64](input[0]) xor JavaMultiplier) and JavaMask
  var words: array[3 * MaxProcesses, int64]
  var wordCount = 0
  var currentTime = 0'i64
  var remaining = processCount
  while remaining > 0:
    var currentTotalTickets = 0'i64
    for index in 0 ..< remaining: currentTotalTickets += ticketCounts[index]
    let winningTicket = javaNextInt(randomState, uint64(currentTotalTickets)) + 1
    var cumulativeTickets = 0'u64
    var selected = remaining
    for index in 0 ..< remaining:
      cumulativeTickets += uint64(ticketCounts[index])
      if cumulativeTickets >= winningTicket:
        selected = index
        break
    if selected == remaining: return -1

    let waitingTime = currentTime
    let turnaroundTime = waitingTime + burstTimes[selected]
    words[wordCount] = processIds[selected]
    words[wordCount + 1] = waitingTime
    words[wordCount + 2] = turnaroundTime
    wordCount += 3
    currentTime += burstTimes[selected]
    for index in selected + 1 ..< remaining:
      processIds[index - 1] = processIds[index]
      burstTimes[index - 1] = burstTimes[index]
      ticketCounts[index - 1] = ticketCounts[index]
    dec remaining

  let outputBytes = wordCount * 8
  if output == nil or capacity < csize_t(outputBytes) or outputBytes > MaxOutputBytes: return -2
  for index in 0 ..< wordCount:
    let bits = cast[uint64](words[index])
    for byteIndex in 0 ..< 8:
      output[index * 8 + byteIndex] = uint8((bits shr (byteIndex * 8)) and 0xff'u64)
  int64(outputBytes)
