proc duplicate_brackets*(packed: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "duplicate_brackets".} =
  if length < 1:
    return -1
  let count = packed[0]
  if count < 0 or count > 256 or length != csize_t(count) + 1:
    return -1
  var depth = 0'i64
  for index in 0'i64 ..< count:
    let ch = packed[index + 1]
    if ch < 32 or ch > 126:
      return -1
    if ch == 40:
      inc depth
    elif ch == 41:
      dec depth
      if depth < 0:
        return -1
  if depth != 0:
    return -1
  var stack: array[256, int64]
  var top = 0
  for index in 0'i64 ..< count:
    let ch = packed[index + 1]
    if ch == 41:
      if top == 0 or stack[top - 1] == 40:
        return 1
      while top > 0 and stack[top - 1] != 40:
        dec top
      if top > 0:
        dec top
    else:
      stack[top] = ch
      inc top
  0
