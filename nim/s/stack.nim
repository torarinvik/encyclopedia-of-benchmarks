## Bounded array-backed integer stack with a deterministic operation-trace checksum.
proc stack_benchmark*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "stack_benchmark".} =
  if length > 1024 or length mod 2 != 0: return -1
  let operationCount = int(length div 2)
  var dataStack: array[256, int64]
  var top = 0
  var checksum: int64 = 0
  for operation in 0 ..< operationCount:
    let opcode = values[2 * operation]
    let payload = values[2 * operation + 1]
    var observed: int64 = 0
    var returnsValue = true
    if opcode == 0:
      if payload < -1000000 or payload > 1000000 or top == 256: return -1
      dataStack[top] = payload
      inc top
      returnsValue = false
    elif opcode == 1:
      if payload != 0 or top == 0: return -1
      dec top
      observed = dataStack[top]
    elif opcode == 2:
      if payload != 0 or top == 0: return -1
      observed = dataStack[top - 1]
    elif opcode == 3:
      if payload != 0: return -1
      observed = if top == 0: 1 else: 0
    else:
      return -1
    if returnsValue: checksum += int64(operation + 1) * (observed + 1000000)
  for index in 0 ..< top:
    checksum += int64(operationCount + index + 1) * (dataStack[index] + 1000000)
  checksum
