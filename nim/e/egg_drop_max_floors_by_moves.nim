const MaxEggs = 32
const MaxMoves = 32

proc egg_drop_max_floors_by_moves*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "egg_drop_max_floors_by_moves".} =
  if input.isNil or length != csize_t(2): return -1
  let eggs = input[0]
  let moves = input[1]
  if eggs < 0 or eggs > MaxEggs or moves < 0 or moves > MaxMoves: return -1
  var covered: array[MaxEggs + 1, int64]
  for _ in 0 ..< int(moves):
    var egg = int(eggs)
    while egg > 0:
      covered[egg] += covered[egg - 1] + 1
      dec egg
  covered[int(eggs)]
