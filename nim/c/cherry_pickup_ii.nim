const MaxDim = 6
const MaxInput = 39
const States = 36

proc cherry_pickup_ii*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "cherry_pickup_ii".} =
  if input.isNil or length < csize_t(6) or length > csize_t(MaxInput): return -1
  let rowsValue = input[0]
  let columnsValue = input[1]
  if rowsValue < 2 or rowsValue > MaxDim or columnsValue < 2 or columnsValue > MaxDim: return -1
  let rows, columns = int(rowsValue), int(columnsValue)
  if int(length) != 2 + rows * columns: return -1
  for i in 0 ..< rows * columns:
    if input[2 + i] < 0 or input[2 + i] > 100: return -1
  var previous: array[States, int64]
  var current: array[States, int64]
  for i in 0 ..< States: previous[i] = -1
  previous[columns - 1] = input[2] + input[2 + columns - 1]
  for row in 1 ..< rows:
    for i in 0 ..< States: current[i] = -1
    for left in 0 ..< columns:
      for right in 0 ..< columns:
        let score = previous[left * columns + right]
        if score < 0: continue
        for leftDelta in -1 .. 1:
          let nextLeft = left + leftDelta
          if nextLeft < 0 or nextLeft >= columns: continue
          for rightDelta in -1 .. 1:
            let nextRight = right + rightDelta
            if nextRight < 0 or nextRight >= columns: continue
            var candidate = score + input[2 + row * columns + nextLeft]
            if nextLeft != nextRight: candidate += input[2 + row * columns + nextRight]
            let slot = nextLeft * columns + nextRight
            current[slot] = max(current[slot], candidate)
    previous = current
  var answer = -1'i64
  for left in 0 ..< columns:
    for right in 0 ..< columns: answer = max(answer, previous[left * columns + right])
  answer
