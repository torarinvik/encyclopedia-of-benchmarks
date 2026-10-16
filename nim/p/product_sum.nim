proc product_sum*(v: ptr UncheckedArray[int64], n: csize_t): int64 {.cdecl, exportc: "product_sum".} =
  if v.isNil or n < 1 or n > 129 or v[0] < 0 or v[0] > 128 or n != csize_t(v[0] + 1): return -1
  var cursor = 0
  var valid = true
  proc parse(depth: int64, nested: bool): int64 =
    if depth > 16: valid = false; return 0
    var total = 0'i64
    while cursor < int(v[0]):
      let x = v[cursor + 1]; inc cursor
      if x == 2002: if not nested: valid = false; return total * depth
      if x == 2001: total += parse(depth + 1, true)
      elif x >= -1000 and x <= 1000: total += x
      else: valid = false; return 0
      if not valid: return 0
    if nested: valid = false
    total * depth
  let answer = parse(1, false)
  if valid and cursor == int(v[0]): answer else: -1
