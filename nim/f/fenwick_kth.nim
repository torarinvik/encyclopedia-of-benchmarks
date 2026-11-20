## Fenwick frequency selection by binary lifting over prefix blocks.
proc lowbit(index: int): int = index and -index

proc fenwick_kth*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "fenwick_kth".} =
  if input.isNil or length < 3 or length > 163: return -1
  let nr = input[0]
  let qr = input[1]
  if nr < 1 or nr > 64 or qr < 0 or qr > 32: return -1
  let n = int(nr)
  let q = int(qr)
  if length != csize_t(2 + n + 3 * q): return -1

  var frequency: array[64, int64]
  var tree: array[65, int64]
  var total = 0'i64
  for i in 0 ..< n:
    let value = input[2 + i]
    if value < 0 or value > 1_000_000: return -1
    frequency[i] = value
    total += value
    let index = i + 1
    tree[index] += value
    let parent = index + (index and -index)
    if parent <= n: tree[parent] += tree[index]

  var result = 0'i64
  var queryNumber = 0
  var cursor = 2 + n
  for _ in 0 ..< q:
    let opcode = input[cursor]
    let first = input[cursor + 1]
    let second = input[cursor + 2]
    cursor += 3
    if opcode == 0:
      if first < 0 or first >= nr or second < -1_000_000 or second > 1_000_000: return -1
      let position = int(first)
      let updated = frequency[position] + second
      if updated < 0 or updated > 1_000_000: return -1
      frequency[position] = updated
      total += second
      var index = position + 1
      while index <= n:
        tree[index] += second
        index += lowbit(index)
    elif opcode == 1:
      if second != 0: return -1
      var answer = -1'i64
      if first > 0 and first <= total:
        var index = 0
        var step = 1
        while step <= n div 2: step *= 2
        var rank = first
        while step != 0:
          let candidate = index + step
          if candidate <= n and tree[candidate] < rank:
            index = candidate
            rank -= tree[candidate]
          step = step div 2
        answer = int64(index)
      result += int64(queryNumber + 1) * (answer + 1)
      inc queryNumber
    else:
      return -1
  result
