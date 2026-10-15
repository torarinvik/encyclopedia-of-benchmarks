## Emit the nearest strictly smaller value to the left of every input value.
proc putI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for b in 0..<8: output[offset+b] = uint8((bits shr (8*b)) and 0xFF'u64)
proc next_smaller_element*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "next_smaller_element".} =
  if input.isNil or length < 1: return -1
  let n64 = input[0]
  if n64 < 0 or n64 > 1024: return -1
  let n = int(n64)
  if length != csize_t(n+1): return -1
  for i in 0..<n:
    if input[i+1] < int64(low(int32)) or input[i+1] > int64(high(int32)): return -1
  if capacity < csize_t(n*8) or (n > 0 and output.isNil): return -2
  var stack: array[1024,int64]
  var top = 0
  for i in 0..<n:
    let value = input[i+1]
    while top > 0 and stack[top-1] >= value: dec top
    putI64Le(output, i*8, if top > 0: stack[top-1] else: -1)
    stack[top] = value
    inc top
  int64(n*8)
