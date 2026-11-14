proc functional_graph_cycle_brent*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "functional_graph_cycle_brent".} =
  if input.isNil or length < 3 or length > 67: return -1
  let n = input[0]
  let start = input[1]
  if n < 1 or n > 64 or start < 0 or start >= n or length != csize_t(n + 2): return -1
  for i in 0 ..< int(n):
    if input[2+i] < 0 or input[2+i] >= n: return -1
  var checkpoint = start
  var moving = input[2+int(start)]
  var power = 1'i64
  var period = 1'i64
  while checkpoint != moving:
    if power == period:
      checkpoint = moving
      power *= 2
      period = 0
    moving = input[2+int(moving)]
    inc period
  var left = start
  var right = start
  for i in 0 ..< int(period): right = input[2+int(right)]
  var tail = 0'i64
  while left != right:
    left = input[2+int(left)]
    right = input[2+int(right)]
    inc tail
  65 * tail + period
