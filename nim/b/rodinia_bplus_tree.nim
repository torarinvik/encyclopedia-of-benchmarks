## Root separator routes point lookup into one of two sorted B+ tree leaves.
proc rodinia_bplus_tree*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "rodinia_bplus_tree".} =
  if input.isNil or length < 7 or length > 31: return -1
  if input[0] < 1 or input[0] > 3 or input[1] < 1 or input[1] > 3 or
      input[2] < 1 or input[2] > 16: return -1
  let leftN = int(input[0]); let rightN = int(input[1]); let queryN = int(input[2])
  if length != csize_t(3 + 2 * (leftN + rightN) + queryN): return -1
  var keys: array[2, array[3, int64]]
  var vals: array[2, array[3, int64]]
  let counts = [leftN, rightN]
  var cursor = 3
  for leaf in 0 ..< 2:
    for slot in 0 ..< counts[leaf]:
      let key = input[cursor]; let value = input[cursor + 1]
      cursor += 2
      if key < -1_000_000 or key > 1_000_000 or value < 0 or value > 1_000_000 or
          (slot > 0 and key <= keys[leaf][slot - 1]): return -1
      keys[leaf][slot] = key; vals[leaf][slot] = value
  if keys[0][leftN - 1] >= keys[1][0]: return -1
  var answer = 0'i64
  for qi in 0 ..< queryN:
    let query = input[cursor]; inc cursor
    if query < -1_000_000 or query > 1_000_000: return -1
    let leaf = if query < keys[1][0]: 0 else: 1
    for slot in 0 ..< counts[leaf]:
      if keys[leaf][slot] == query:
        answer += int64(qi + 1) * (vals[leaf][slot] + 1)
        break
  answer
