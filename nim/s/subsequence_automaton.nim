## Uncompiled and unexecuted next-occurrence automaton draft.
proc subsequence_automaton*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "subsequence_automaton".} =
  if input.isNil or length < 2 or length > 354: return -1
  if input[0] < 0 or input[0] > 64 or input[1] < 0 or input[1] > 32: return -1
  let n = int(input[0])
  let queries = int(input[1])
  if int(length) < 2+n: return -1
  for i in 0 ..< n:
    if input[2+i] < 0 or input[2+i] > 3: return -1
  var next: array[65, array[4, int]]
  for symbol in 0 ..< 4: next[n][symbol] = n
  var row = n
  while row > 0:
    dec row
    next[row] = next[row+1]
    next[row][int(input[2+row])] = row
  var position = 2+n
  var total = 0
  var answer = 0'i64
  for query in 0 ..< queries:
    if position == int(length) or input[position] < 0 or input[position] > 256: return -1
    let count = int(input[position])
    inc position
    if count > 256-total or count > int(length)-position: return -1
    var cursor = 0
    var matches = true
    for i in 0 ..< count:
      let symbol = input[position+i]
      if symbol < 0 or symbol > 3: return -1
      if matches:
        let found = next[cursor][int(symbol)]
        if found == n: matches = false
        else: cursor = found+1
    if matches: answer += int64(query+1)
    position += count
    total += count
  if position == int(length): answer else: -1
