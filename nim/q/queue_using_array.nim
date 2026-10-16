const MaxQ = 512
const MaxInput = 1025
const ChecksumOffset = 128'i64

proc queue_using_array*(packed: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "queue_using_array".} =
  if packed.isNil or length < 1 or length > MaxInput: return -1
  let qv = packed[0]
  if qv < 0 or qv > MaxQ or length != csize_t(1 + qv * 2): return -1
  let q = int(qv)
  for i in 0 ..< q:
    let op = packed[1 + i * 2]
    let value = packed[2 + i * 2]
    if op == 0:
      if value < -128 or value > 127: return -1
    elif op == 1:
      if value != 0: return -1
    else:
      return -1
  var values: array[10, int16]
  var front = -1
  var rear = -1
  var checksum = 0'i64
  var ordinal = 0'i64
  for i in 0 ..< q:
    let op = packed[1 + i * 2]
    let value = packed[2 + i * 2]
    if op == 0:
      if rear == 9: continue
      if front == -1 and rear == -1:
        front = 0
        rear = 0
        values[0] = int16(value)
      elif rear < 10:
        inc rear
        values[rear] = int16(value)
    else:
      var dequeued = 0'i64
      if front != -1:
        if front == rear:
          dequeued = int64(values[front])
          front = -1
          rear = -1
        else:
          dequeued = int64(values[front])
          inc front
      inc ordinal
      checksum += ordinal * (dequeued + ChecksumOffset)
  checksum
