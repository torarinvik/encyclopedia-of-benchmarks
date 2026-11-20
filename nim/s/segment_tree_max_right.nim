## Point updates and sum-monoid max_right boundary searches.
proc segment_tree_max_right*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "segment_tree_max_right".} =
  if input.isNil or length < 2 or length > 55: return -1
  let nr = input[0]
  let qr = input[1]
  if nr < 0 or nr > 16 or qr < 0 or qr > 12: return -1
  let n = int(nr)
  let operations = int(qr)
  if length != csize_t(2 + n + 3 * operations): return -1

  var tree: array[64, int64]
  var size = 1
  while size < n: size *= 2
  for i in 0 ..< n:
    let value = input[2 + i]
    if value < 0 or value > 1000: return -1
    tree[size + i] = value
  var node = size
  while node > 1:
    dec node
    tree[node] = tree[2 * node] + tree[2 * node + 1]

  var queryIndex = 0
  var result = 0'i64
  var cursor = 2 + n
  for _ in 0 ..< operations:
    let opcode = input[cursor]
    let first = input[cursor + 1]
    let second = input[cursor + 2]
    cursor += 3
    if opcode == 0:
      if first < 0 or first >= nr or second < 0 or second > 1000: return -1
      node = size + int(first)
      tree[node] = second
      while node > 1:
        node = node div 2
        tree[node] = tree[2 * node] + tree[2 * node + 1]
    elif opcode == 1:
      if first < 0 or first > nr or second < 0 or second > 16000: return -1
      let left = int(first)
      var boundary = n
      if left < n:
        var position = left + size
        var accumulated = 0'i64
        var done = false
        while not done:
          while (position and 1) == 0: position = position div 2
          if accumulated + tree[position] > second:
            while position < size:
              position *= 2
              if accumulated + tree[position] <= second:
                accumulated += tree[position]
                inc position
            boundary = min(position - size, n)
            done = true
          else:
            accumulated += tree[position]
            inc position
            if (position and (position - 1)) == 0: done = true
      result = result or (int64(boundary) shl (5 * queryIndex))
      inc queryIndex
    else:
      return -1
  result
