const
  MaxWords = 8
  MaxWordLength = 8
  HashCapacity = 17
  MaxInput = 74

proc isPalindrome(words: array[MaxWords, array[MaxWordLength, int]], id, left, right: int): bool =
  var lo = left
  var hi = right - 1
  while lo < hi:
    if words[id][lo] != words[id][hi]: return false
    inc lo
    dec hi
  true

proc encode(words: array[MaxWords, array[MaxWordLength, int]], id, left, right: int, reverse: bool): int64 =
  result = 1
  if reverse:
    var i = right
    while i > left:
      dec i
      result = result * 5 + int64(words[id][i] + 1)
  else:
    for i in left ..< right: result = result * 5 + int64(words[id][i] + 1)

proc findSlot(keys: array[HashCapacity, int64], key: int64): int =
  result = int(key mod HashCapacity.int64)
  while keys[result] != 0 and keys[result] != key: result = (result + 1) mod HashCapacity

proc mark(keys: array[HashCapacity, int64], heads: array[HashCapacity, int], next: array[MaxWords, int],
          key: int64, fixed: int, fixedRight: bool, found: var array[MaxWords, array[MaxWords, bool]]) =
  let slot = findSlot(keys, key)
  if keys[slot] != key: return
  var id = heads[slot]
  while id >= 0:
    if id != fixed:
      if fixedRight: found[id][fixed] = true
      else: found[fixed][id] = true
    id = next[id]

proc palindrome_pairs*(input: ptr UncheckedArray[int64], n: csize_t,
                       output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "palindrome_pairs".} =
  if input.isNil or n < 1 or n > MaxInput.csize_t or input[0] < 0 or input[0] > MaxWords.int64: return -1
  let count = int(input[0])
  var words: array[MaxWords, array[MaxWordLength, int]]
  var sizes: array[MaxWords, int]
  var cursor = 1
  for id in 0 ..< count:
    if cursor >= int(n) or input[cursor] < 0 or input[cursor] > MaxWordLength.int64: return -1
    let size = int(input[cursor]); inc cursor
    if cursor + size > int(n): return -1
    sizes[id] = size
    for k in 0 ..< size:
      if input[cursor] < 0 or input[cursor] >= 4: return -1
      words[id][k] = int(input[cursor]); inc cursor
  if cursor != int(n): return -1

  var keys: array[HashCapacity, int64]
  var next: array[MaxWords, int]
  var tableHeads: array[HashCapacity, int]
  for i in 0 ..< HashCapacity: tableHeads[i] = -1
  for i in 0 ..< MaxWords: next[i] = -1
  for id in 0 ..< count:
    let key = encode(words, id, 0, sizes[id], false)
    let slot = findSlot(keys, key)
    if keys[slot] == 0:
      keys[slot] = key
      tableHeads[slot] = id
    else:
      next[id] = tableHeads[slot]
      tableHeads[slot] = id
  var found: array[MaxWords, array[MaxWords, bool]]
  for id in 0 ..< count:
    for split in 0 .. sizes[id]:
      if isPalindrome(words, id, 0, split): mark(keys, tableHeads, next, encode(words, id, split, sizes[id], true), id, true, found)
      if isPalindrome(words, id, split, sizes[id]): mark(keys, tableHeads, next, encode(words, id, 0, split, true), id, false, found)
  var staged: array[MaxWords * (MaxWords - 1), uint8]
  var bytes = 0
  for left in 0 ..< count:
    for right in 0 ..< count:
      if left != right and found[left][right]: staged[bytes] = uint8(left * MaxWords + right); inc bytes
  if output.isNil or capacity < csize_t(bytes): return -2
  for i in 0 ..< bytes: output[i] = staged[i]
  int64(bytes)
