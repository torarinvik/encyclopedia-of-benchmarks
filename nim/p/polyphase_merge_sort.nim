import std/ffi

const MaxItems = 256
const RunSize = 8
const MaxRuns = 34

type
  Tape = array[MaxItems, int64]
  Tapes = array[3, Tape]
  RunRow = array[MaxRuns, uint32]
  RunTable = array[3, RunRow]
  TapeCounts = array[3, uint32]

proc placeRun(input: ptr UncheckedArray[int64], inputLength: int, runIndex: uint32,
              tape: int, tapes: var Tapes, starts, lengths: var RunTable,
              counts, writeOffsets: var TapeCounts) =
  let slot = int(counts[tape])
  inc counts[tape]
  let start = int(writeOffsets[tape])
  let source = int(runIndex) * RunSize
  let runLength = min(inputLength - source, RunSize)
  for i in 0 ..< runLength: tapes[tape][start + i] = input[source + i]
  for i in 1 ..< runLength:
    let value = tapes[tape][start + i]
    var position = i
    while position > 0 and tapes[tape][start + position - 1] > value:
      tapes[tape][start + position] = tapes[tape][start + position - 1]
      dec position
    tapes[tape][start + position] = value
  starts[tape][slot] = uint32(start)
  lengths[tape][slot] = uint32(runLength)
  writeOffsets[tape] += uint32(runLength)

proc placeDummy(tape: int, starts, lengths: var RunTable,
                counts: var TapeCounts, writeOffsets: TapeCounts) =
  let slot = int(counts[tape])
  inc counts[tape]
  starts[tape][slot] = writeOffsets[tape]
  lengths[tape][slot] = 0

proc mergeRun(tapes: var Tapes, starts, lengths: var RunTable,
              counts, readIndices, writeOffsets: var TapeCounts,
              leftTape, rightTape, outputTape: int) =
  let leftSlot = int(readIndices[leftTape])
  let rightSlot = int(readIndices[rightTape])
  inc readIndices[leftTape]
  inc readIndices[rightTape]
  let leftStart = int(starts[leftTape][leftSlot])
  let rightStart = int(starts[rightTape][rightSlot])
  let leftLength = int(lengths[leftTape][leftSlot])
  let rightLength = int(lengths[rightTape][rightSlot])
  let outputSlot = int(counts[outputTape])
  inc counts[outputTape]
  let outputStart = int(writeOffsets[outputTape])
  var left = 0
  var right = 0
  var written = 0
  while left < leftLength and right < rightLength:
    if tapes[leftTape][leftStart + left] <= tapes[rightTape][rightStart + right]:
      tapes[outputTape][outputStart + written] = tapes[leftTape][leftStart + left]
      inc left
    else:
      tapes[outputTape][outputStart + written] = tapes[rightTape][rightStart + right]
      inc right
    inc written
  while left < leftLength:
    tapes[outputTape][outputStart + written] = tapes[leftTape][leftStart + left]
    inc left
    inc written
  while right < rightLength:
    tapes[outputTape][outputStart + written] = tapes[rightTape][rightStart + right]
    inc right
    inc written
  starts[outputTape][outputSlot] = uint32(outputStart)
  lengths[outputTape][outputSlot] = uint32(written)
  writeOffsets[outputTape] += uint32(written)

proc polyphase_merge_sort*(values: ptr UncheckedArray[int64], length: csize_t)
    {.cdecl, exportc: "polyphase_merge_sort".} =
  if values.isNil or length < csize_t(2) or length > csize_t(MaxItems): return
  let n = int(length)
  var tapes: Tapes
  var starts, runLengths: RunTable
  var counts, readIndices, writeOffsets: TapeCounts
  let initialRuns = uint32((n + RunSize - 1) div RunSize)
  var quotaA = 1'u32
  var quotaB = 0'u32
  while quotaA + quotaB < initialRuns:
    let next = quotaA + quotaB
    quotaB = quotaA
    quotaA = next
  var run = 0'u32
  for _ in 0'u32 ..< quotaA:
    if run < initialRuns: placeRun(values, n, run, 0, tapes, starts, runLengths, counts, writeOffsets)
    else: placeDummy(0, starts, runLengths, counts, writeOffsets)
    inc run
  for _ in 0'u32 ..< quotaB:
    if run < initialRuns: placeRun(values, n, run, 1, tapes, starts, runLengths, counts, writeOffsets)
    else: placeDummy(1, starts, runLengths, counts, writeOffsets)
    inc run

  var inputA = 0'u32
  var inputB = 1'u32
  var output = 2'u32
  var remainingTotal = counts[0] + counts[1]
  while remainingTotal > 1:
    let a = int(inputA)
    let b = int(inputB)
    let outTape = int(output)
    let availableA = counts[a] - readIndices[a]
    let availableB = counts[b] - readIndices[b]
    if availableA == 0 or availableB == 0: break
    counts[outTape] = 0
    readIndices[outTape] = 0
    writeOffsets[outTape] = 0
    let pairs = min(availableA, availableB)
    for _ in 0'u32 ..< pairs: mergeRun(tapes, starts, runLengths, counts, readIndices, writeOffsets, a, b, outTape)
    let leftA = counts[a] - readIndices[a]
    let leftB = counts[b] - readIndices[b]
    remainingTotal = leftA + leftB + counts[outTape]
    if remainingTotal <= 1 or (leftA == 0 and leftB == 0): break
    if leftA > 0:
      let exhausted = inputB
      inputB = output
      output = exhausted
    else:
      let exhausted = inputA
      inputA = output
      output = exhausted

  for tape in 0 ..< 3:
    if readIndices[tape] < counts[tape]:
      let slot = int(readIndices[tape])
      if int(runLengths[tape][slot]) == n:
        let start = int(starts[tape][slot])
        for i in 0 ..< n: values[i] = tapes[tape][start + i]
        return
