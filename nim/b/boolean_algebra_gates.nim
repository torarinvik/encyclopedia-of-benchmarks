const MaxInputCount = 4096

proc boolean_algebra_gates*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "boolean_algebra_gates".} =
  if values == nil or length < 2 or length > csize_t(MaxInputCount + 2): return -1
  let gate = values[0]
  let count = values[1]
  if gate < 0 or gate > 5 or count < 0 or count > MaxInputCount: return -1
  if csize_t(count) != length - 2: return -1
  if gate == 2 and count != 1: return -1
  var result = if gate == 0 or gate == 4: 1'i64 else: 0'i64
  for index in 0 ..< int(count):
    let bit = values[index + 2]
    if bit != 0 and bit != 1: return -1
    if gate == 0 or gate == 4: result = result and bit
    elif gate == 1 or gate == 5: result = result or bit
    elif gate == 2: result = 1 - bit
    else: result = result xor bit
  if gate == 4 or gate == 5: result = 1 - result
  result
