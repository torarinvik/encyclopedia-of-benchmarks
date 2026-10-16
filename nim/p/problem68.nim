proc nextPermutation(indices: var array[10, int], length: int): bool =
  var pivot = length - 2
  while pivot >= 0 and indices[pivot] >= indices[pivot + 1]: dec pivot
  if pivot < 0: return false
  var successor = length - 1
  while indices[successor] <= indices[pivot]: dec successor
  swap(indices[pivot], indices[successor])
  var left = pivot + 1
  var right = length - 1
  while left < right:
    swap(indices[left], indices[right])
    inc left
    dec right
  true

proc problem68*(gonSide: int64): int64 {.cdecl, exportc: "problem68".} =
  if gonSide < 3 or gonSide > 5: return -1
  let n = int(gonSide)
  let length = 2 * n
  var values: array[10, int]
  var cursor = 0
  for value in countdown(n + 1, 1):
    values[cursor] = value
    inc cursor
  for value in (n + 2)..(2 * n):
    values[cursor] = value
    inc cursor
  var indices: array[10, int]
  for i in 0..<length: indices[i] = i
  while true:
    template at(position: int): int = values[indices[position]]
    let total = at(0) + at(1) + at(2)
    var magic = true
    var minimumOuter = at(0)
    for line in 1..<n:
      let outer = if line == n - 1: 2 * n - 1 else: 2 * line + 1
      let innerLeft = 2 * line
      let innerRight = if line == n - 1: 1 else: 2 * line + 2
      if at(outer) + at(innerLeft) + at(innerRight) != total: magic = false
      minimumOuter = min(minimumOuter, at(outer))
    if magic and at(0) == minimumOuter:
      var result = 0'i64
      for line in 0..<n:
        let outer = if line == 0: 0 elif line == n - 1: 2 * n - 1 else: 2 * line + 1
        let innerLeft = if line == 0: 1 else: 2 * line
        let innerRight = if line == n - 1: 1 elif line == 0: 2 else: 2 * line + 2
        for value in [at(outer), at(innerLeft), at(innerRight)]:
          result = result * (if value >= 10: 100 else: 10) + value.int64
      return result
    if not nextPermutation(indices, length): break
  -1
