const
  Modulus = 998_244_353'i64
  MaxLength = 210

type Record = object
  priority, a, b: int64

proc point_set_range_sort_range_composite*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "point_set_range_sort_range_composite".} =
  if input == nil or length < 2 or length > csize_t(MaxLength): return -1
  if input[0] < 1 or input[0] > 16 or input[1] < 1 or input[1] > 32: return -1
  let n = int(input[0])
  let q = int(input[1])
  if int(length) < 2 + 3 * n: return -1
  var records: array[16, Record]
  var seen: array[48, int64]
  var seenCount = 0
  var cursor = 2
  for i in 0 ..< n:
    let p = input[cursor]
    let a = input[cursor + 1]
    let b = input[cursor + 2]
    cursor += 3
    if p < 0 or p > 1_000_000_000 or a < 1 or a >= Modulus or b < 0 or b >= Modulus: return -1
    for j in 0 ..< seenCount:
      if seen[j] == p: return -1
    seen[seenCount] = p
    inc seenCount
    records[i] = Record(priority: p, a: a, b: b)

  var checksum = 0'i64
  var queryNumber = 0'i64
  for _ in 0 ..< q:
    if cursor >= int(length): return -1
    let opcode = input[cursor]
    inc cursor
    if opcode == 0:
      if int(length) - cursor < 4: return -1
      let index = input[cursor]
      let p = input[cursor + 1]
      let a = input[cursor + 2]
      let b = input[cursor + 3]
      cursor += 4
      if index < 0 or index >= int64(n) or p < 0 or p > 1_000_000_000 or a < 1 or a >= Modulus or b < 0 or b >= Modulus: return -1
      for j in 0 ..< seenCount:
        if seen[j] == p: return -1
      seen[seenCount] = p
      inc seenCount
      records[int(index)] = Record(priority: p, a: a, b: b)
    elif opcode == 1:
      if int(length) - cursor < 3: return -1
      let left = input[cursor]
      let right = input[cursor + 1]
      let x = input[cursor + 2]
      cursor += 3
      if left < 0 or left >= right or right > int64(n) or x < 0 or x >= Modulus: return -1
      var answer = x
      for i in int(left) ..< int(right): answer = (records[i].a * answer + records[i].b) mod Modulus
      inc queryNumber
      checksum = (checksum + queryNumber * answer) mod Modulus
    elif opcode == 2 or opcode == 3:
      if int(length) - cursor < 2: return -1
      let left = input[cursor]
      let right = input[cursor + 1]
      cursor += 2
      if left < 0 or left >= right or right > int64(n): return -1
      for i in (int(left) + 1) ..< int(right):
        let item = records[i]
        var j = i
        while j > int(left) and (if opcode == 2: records[j - 1].priority > item.priority else: records[j - 1].priority < item.priority):
          records[j] = records[j - 1]
          dec j
        records[j] = item
    else:
      return -1
  if cursor != int(length): return -1
  checksum
