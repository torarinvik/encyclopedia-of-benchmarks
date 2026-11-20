const MaxInput = 1095
const MaxCells = 64

proc putWord(output: ptr UncheckedArray[uint8], word: int, value: int64) =
  var bits = uint64(value)
  for byte in 0 ..< 8:
    output[word * 8 + byte] = uint8(bits and 255'u64)
    bits = bits shr 8

proc forest_fire_synchronous_stochastic_ca*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "forest_fire_synchronous_stochastic_ca".} =
  if input.isNil or length < 6 or length > csize_t(MaxInput): return -1
  if input[0] < 1 or input[0] > 8 or input[1] < 1 or input[1] > 8 or
      input[2] < 0 or input[2] > 8 or input[3] != 10000 or
      input[4] < 0 or input[4] > 10000 or input[5] < 0 or input[5] > 10000: return -1
  let rows = int(input[0])
  let cols = int(input[1])
  let steps = int(input[2])
  let cells = rows * cols
  if length != csize_t(6 + cells + 2 * steps * cells): return -1
  for i in 0 ..< cells:
    if input[6 + i] < 0 or input[6 + i] > 2: return -1
  for row in 0 ..< rows:
    for col in 0 ..< cols:
      if (row == 0 or row == rows - 1 or col == 0 or col == cols - 1) and input[6 + row * cols + col] != 0: return -1
  let tape = 6 + cells
  for i in 0 ..< 2 * steps * cells:
    if input[tape + i] < 0 or input[tape + i] >= 10000: return -1
  let bytes = (1 + 3 * steps + cells) * 8
  if output.isNil or capacity < csize_t(bytes): return -2

  var current: array[MaxCells, uint8]
  var next: array[MaxCells, uint8]
  for i in 0 ..< cells: current[i] = uint8(input[6 + i])
  putWord(output, 0, int64(steps))
  for tick in 0 ..< steps:
    for row in 0 ..< rows:
      for col in 0 ..< cols:
        let site = row * cols + col
        if row == 0 or row == rows - 1 or col == 0 or col == cols - 1:
          next[site] = 0
        else:
          case current[site]
          of 2'u8:
            next[site] = 0
          of 0'u8:
            next[site] = (if input[tape + tick * cells + site] < input[4]: 1'u8 else: 0'u8)
          else:
            var nearFire = false
            for r in max(0, row - 1) .. min(rows - 1, row + 1):
              for c in max(0, col - 1) .. min(cols - 1, col + 1):
                if (r != row or c != col) and current[r * cols + c] == 2: nearFire = true
            let strike = input[tape + steps * cells + tick * cells + site]
            next[site] = (if nearFire or strike < input[5]: 2'u8 else: 1'u8)
    var totals: array[3, int64]
    for i in 0 ..< cells: totals[int(next[i])] += 1
    let base = 1 + 3 * tick
    for state in 0 ..< 3: putWord(output, base + state, totals[state])
    for i in 0 ..< cells: current[i] = next[i]
  let finalBase = 1 + 3 * steps
  for i in 0 ..< cells: putWord(output, finalBase + i, int64(current[i]))
  int64(bytes)
