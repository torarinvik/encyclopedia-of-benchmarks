const MaxWidth = 32'i64
const MaxParseableLength = 2

proc countTilings(width: int64): int64 =
  var state0 = 1'i64
  var state1 = 0'i64
  var state2 = 0'i64
  var state3 = 0'i64
  for _ in 0 ..< int(width):
    let next0 = state0 + state3
    let next1 = state0 + state2
    let next2 = state0 + state1
    let next3 = state0 + state1 + state2
    state0 = next0
    state1 = next1
    state2 = next2
    state3 = next3
  state0

proc domino_l_tromino_tilings_2xn*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "domino_l_tromino_tilings_2xn".} =
  if input == nil or length < 1 or length > csize_t(MaxParseableLength): return -1
  if length != 1 or input[0] < 0 or input[0] > MaxWidth: return -1
  countTilings(input[0])
