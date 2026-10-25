## Clean-room bounded profile of Embench-IoT Statemate's fixed control path.
## SPDX-License-Identifier: GPL-3.0-or-later
const
  StateCount = 16
  BitlistCount = 64
  TimerBytes = 12
  OutputBytes = BitlistCount + StateCount + TimerBytes
  MaxRuns = 256
  DefaultStates: array[StateCount, uint8] = [0'u8, 0, 0, 3, 2, 1, 1, 0, 0, 0, 0, 0, 2, 1, 0, 1]

proc settle(snapshot: ptr UncheckedArray[uint8]) =
  var bitlist: array[BitlistCount, uint8]
  var states: array[StateCount, uint8]
  var timers: array[TimerBytes, uint8]
  var stable = false
  while not stable:
    stable = true
    for index in 0 ..< StateCount:
      if states[index] == 0 and DefaultStates[index] != 0:
        states[index] = DefaultStates[index]
        stable = false
  bitlist[5] = 1
  for index in 0 ..< BitlistCount: snapshot[index] = bitlist[index]
  for index in 0 ..< StateCount: snapshot[BitlistCount + index] = states[index]
  for index in 0 ..< TimerBytes: snapshot[BitlistCount + StateCount + index] = timers[index]

proc statemate*(input: ptr UncheckedArray[int64], inputLength: csize_t,
                output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
                {.cdecl, exportc: "statemate".} =
  if input.isNil or inputLength != 1 or input[0] < 1 or input[0] > int64(MaxRuns): return -1
  if output.isNil or outputCapacity < csize_t(OutputBytes): return -2
  var staged: array[OutputBytes, uint8]
  for _ in 0 ..< int(input[0]): settle(addr staged[0])
  for index in 0 ..< OutputBytes: output[index] = staged[index]
  int64(OutputBytes)
