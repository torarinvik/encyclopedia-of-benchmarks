proc previousBucket(index: int): int =
  (index and (index + 1)) - 1

proc maximumFenwickTree*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "maximum_fenwick_tree".} =
  if input == nil or length < 2 or length > 194: return -1
  if input[0] < 1 or input[0] > 64 or input[1] < 0 or input[1] > 64: return -1
  let size = int(input[0])
  let opCount = int(input[1])
  if int(length) != 2 + 3 * opCount: return -1
  var values: array[64, int32]
  var tree: array[64, int32]
  var results: array[64, int64]
  var resultCount = 0
  for op in 0 ..< opCount:
    let pos = 2 + 3 * op
    let opcode = input[pos]
    let first = input[pos + 1]
    let second = input[pos + 2]
    if opcode == 0:
      if first < 0 or first >= int64(size) or second < 0 or second > int64(high(int32)): return -1
      var index = int(first)
      let oldValue = values[index]
      let value = int32(second)
      values[index] = value
      while index < size:
        let oldMax = tree[index]
        if value > oldMax:
          tree[index] = value
        elif oldValue == oldMax:
          let left = previousBucket(index) + 1
          var maximum = value
          var child = index - 1
          while child >= left:
            maximum = max(maximum, tree[child])
            if maximum == oldMax: break
            child = previousBucket(child)
          tree[index] = maximum
          if maximum == oldMax: break
        else:
          break
        index = index or (index + 1)
    elif opcode == 1:
      if first < 0 or first > second or second > int64(size): return -1
      var maximum = 0'i32
      var right = int(second) - 1
      while first <= int64(right):
        let currentLeft = right and (right + 1)
        if first <= int64(currentLeft):
          maximum = max(maximum, tree[right])
          right = currentLeft - 1
        else:
          maximum = max(maximum, values[right])
          dec right
      results[resultCount] = int64(maximum)
      inc resultCount
    else:
      return -1
  let bytes = resultCount * 8
  if output == nil or outputCapacity < csize_t(bytes): return -2
  for i in 0 ..< resultCount:
    let bits = cast[uint64](results[i])
    for b in 0 ..< 8:
      output[8 * i + b] = uint8((bits shr (8 * b)) and 255)
  int64(bytes)
