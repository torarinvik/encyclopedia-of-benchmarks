const MaxValues = 1024

proc bingo_sort*(values: ptr UncheckedArray[int64], length: csize_t)
    {.cdecl, exportc: "bingo_sort".} =
  if length > csize_t(MaxValues) or length < 2: return
  let n = int(length)
  var bingo = values[0]
  for index in 1 ..< n:
    if values[index] < bingo: bingo = values[index]
  var nextPosition = 0
  while nextPosition < n:
    var hasNext = false
    var nextBingo = 0'i64
    var index = nextPosition
    while index < n:
      if values[index] == bingo:
        swap(values[index], values[nextPosition])
        inc nextPosition
      else:
        if not hasNext or values[index] < nextBingo:
          nextBingo = values[index]
          hasNext = true
      inc index
    if nextPosition == n: break
    bingo = nextBingo
