proc indexed_deque*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc.} =
  if input == nil or length < 1 or length > 513: return -1
  if input[0] < 1 or input[0] > 256: return -1
  let q = int(input[0])
  if length != csize_t(1+2*q): return -1
  var items, answers: array[256,int64]
  var head, size, count = 0
  for i in 0 ..< q:
    let op = input[1+2*i]
    let arg = input[2+2*i]
    if op == 0 or op == 1:
      if arg < -1_000_000 or arg > 1_000_000 or size == 256: return -1
      if op == 0:
        head = (head+255) mod 256
        items[head] = arg
      else: items[(head+size) mod 256] = arg
      inc size
    elif op == 2 or op == 3:
      if arg != 0 or size == 0: return -1
      if op == 2: head = (head+1) mod 256
      dec size
    elif op == 4:
      if arg < 0 or arg >= int64(size): return -1
      answers[count] = items[(head+int(arg)) mod 256]
      inc count
    else: return -1
  if count == 0: return -1
  if output == nil or capacity < csize_t(8*count): return -2
  for i in 0 ..< count:
    let bits = cast[uint64](answers[i])
    for byte in 0 ..< 8: output[8*i+byte] = uint8((bits shr (8*byte)) and 255'u64)
  int64(8*count)
