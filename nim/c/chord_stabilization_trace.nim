proc between(ids: array[16, int], ring, left, item, right: int): bool =
  let distance = (ids[item]-ids[left]+ring) mod ring
  let span = (ids[right]-ids[left]+ring) mod ring
  distance > 0 and (span == 0 or distance < span)

proc chord_stabilization_trace*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "chord_stabilization_trace".} =
  if input.isNil or length < 6 or length > 115: return -1
  if input[0] < 1 or input[0] > 6 or input[1] < 1 or input[1] > 16 or input[2] < 0 or input[2] > 64: return -1
  let ring = 1 shl int(input[0])
  let n = int(input[1])
  let q = int(input[2])
  if n > ring or length != csize_t(3+3*n+q): return -1
  var ids, succ, pred: array[16, int]
  for i in 0..<n:
    if input[3+i] < 0 or input[3+i] >= int64(ring): return -1
    if i > 0 and input[3+i] <= int64(ids[i-1]): return -1
    if input[3+n+i] < 0 or input[3+n+i] >= int64(n) or input[3+2*n+i] < -1 or input[3+2*n+i] >= int64(n): return -1
    ids[i] = int(input[3+i]); succ[i] = int(input[3+n+i]); pred[i] = int(input[3+2*n+i])
  for i in 0..<q:
    if input[3+3*n+i] < 0 or input[3+3*n+i] >= int64(n): return -1
  for i in 0..<q:
    let node = int(input[3+3*n+i])
    let candidate = pred[succ[node]]
    if candidate >= 0 and between(ids, ring, node, candidate, succ[node]): succ[node] = candidate
    let receiver = succ[node]
    if pred[receiver] < 0 or between(ids, ring, pred[receiver], node, receiver): pred[receiver] = node
  if output.isNil or capacity < csize_t(2*n): return -2
  for i in 0..<n:
    output[i] = uint8(succ[i])
    output[n+i] = if pred[i] < 0: 255'u8 else: uint8(pred[i])
  int64(2*n)
