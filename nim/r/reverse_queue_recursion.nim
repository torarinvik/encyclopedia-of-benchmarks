const
  MaxQueueLength = 32
  MaxInputLength = 34

proc reverseQueueRecursive(queue: var array[MaxQueueLength, uint8], capacity: int,
                           front, size: var int) =
  if size == 0: return
  let value = queue[front]
  front = (front + 1) mod capacity
  dec size
  reverseQueueRecursive(queue, capacity, front, size)
  let rear = (front + size) mod capacity
  queue[rear] = value
  inc size

proc reverse_queue_recursion*(input: ptr UncheckedArray[int64], inputLength: csize_t,
                              output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "reverse_queue_recursion".} =
  if input == nil:
    if inputLength != 1: return -1
    return if output == nil: -2 else: 0
  if inputLength < 1 or inputLength > csize_t(MaxInputLength): return -1
  if input[0] < 0 or input[0] > MaxQueueLength: return -1
  let queueLength = int(input[0])
  if int(inputLength) != queueLength + 1: return -1
  for index in 0 ..< queueLength:
    if input[index + 1] < 0 or input[index + 1] > 255: return -1
  if output == nil or outputCapacity < csize_t(queueLength): return -2

  var queue: array[MaxQueueLength, uint8]
  for index in 0 ..< queueLength: queue[index] = uint8(input[index + 1])
  var front = 0
  var size = queueLength
  reverseQueueRecursive(queue, queueLength, front, size)
  for index in 0 ..< queueLength:
    output[index] = queue[(front + index) mod queueLength]
  int64(queueLength)
