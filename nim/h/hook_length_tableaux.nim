## Independent hook-length count; see package README.
const Prime = 998244353'i64

proc hook_length_tableaux*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "hook_length_tableaux".} =
  if input.isNil or length == 0 or input[0] < 0 or input[0] > 65536: return -1
  let rows = int(input[0])
  if length != csize_t(rows + 1): return -1
  var total = 0'i64
  var previous = 1000000'i64
  for i in 1 .. rows:
    let width = input[i]
    if width < 1 or width > previous: return -1
    total += width
    if total > 1000000: return -1
    previous = width
  var hooks = 1'i64
  var height = rows
  if rows > 0:
    for col in 0'i64 ..< input[1]:
      while height > 0 and input[height] <= col: dec height
      for row in 0 ..< height:
        let h = input[row + 1] - col + int64(height - row - 1)
        hooks = (hooks * h) mod Prime
  var factorial = 1'i64
  for i in 2'i64 .. total: factorial = (factorial * i) mod Prime
  var inverse = 1'i64
  var exponent = Prime - 2
  while exponent > 0:
    if (exponent and 1) != 0: inverse = (inverse * hooks) mod Prime
    hooks = (hooks * hooks) mod Prime
    exponent = exponent shr 1
  result = (factorial * inverse) mod Prime
