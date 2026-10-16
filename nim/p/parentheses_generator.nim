const Catalan = [1, 1, 2, 5, 14, 42, 132]
proc parentheses_generator*(v: ptr UncheckedArray[int64], n: csize_t, output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "parentheses_generator".} =
  if v.isNil or n != 1 or v[0] < 0 or v[0] > 6: return -1
  let pairs = int(v[0]); let needed = 2 + Catalan[pairs] * 2 * pairs
  if output.isNil or int(capacity) < needed: return -2
  output[0] = uint8(Catalan[pairs]); output[1] = uint8(Catalan[pairs] shr 8)
  var path: array[12, uint8]; var index = 0
  proc generate(opens, closes: int) =
    if opens + closes == pairs * 2:
      for i in 0..<pairs * 2: output[2 + index * pairs * 2 + i] = path[i]
      inc index; return
    if opens < pairs:
      path[opens + closes] = 40; generate(opens + 1, closes)
    if closes < opens:
      path[opens + closes] = 41; generate(opens, closes + 1)
  generate(0, 0)
  int64(needed)
