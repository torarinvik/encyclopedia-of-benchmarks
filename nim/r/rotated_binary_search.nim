proc rotated_binary_search*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "rotated_binary_search".} =
  if input.isNil or length < 2 or input[0] < 0 or input[0] > 256: return -2
  let n = int(input[0])
  if length != csize_t(n + 2): return -2
  if n == 0: return -1
  let key = input[n + 1]
  if key < int64(low(int32)) or key > int64(high(int32)): return -2
  var drops = 0
  for i in 0 ..< n:
    if input[i + 1] < int64(low(int32)) or input[i + 1] > int64(high(int32)): return -2
    if i > 0 and input[i] > input[i + 1]: inc drops
  if drops > 1 or (drops == 1 and input[n] > input[1]): return -2
  var left = 0
  var right = n - 1
  while left <= right:
    let middle = left + (right - left) div 2
    let midValue = input[middle + 1]
    if key == midValue: return int64(middle)
    if input[left + 1] == midValue and midValue == input[right + 1]:
      inc left
      if right == 0: break
      dec right
      continue
    if input[left + 1] <= midValue:
      if input[left + 1] <= key and key < midValue:
        if middle == 0: break
        right = middle - 1
      else:
        left = middle + 1
    elif midValue < key and key <= input[right + 1]:
      left = middle + 1
    else:
      if middle == 0: break
      right = middle - 1
  -1
