type I64Input = ptr UncheckedArray[int64]
type U8Output = ptr UncheckedArray[uint8]

proc putI64Le(output: U8Output, offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0..<8: output[offset + byte] = uint8((bits shr (8 * byte)) and 0xFF'u64)

proc difference_array*(input: I64Input, length: csize_t, output: U8Output, capacity: csize_t): int64
    {.cdecl, exportc: "difference_array".} =
  if input == nil or length < 2: return -1
  let rawN = input[0]
  let rawQ = input[1]
  if rawN < 1 or rawN > 64 or rawQ < 0 or rawQ > 64: return -1
  let n = int(rawN)
  let q = int(rawQ)
  if length != csize_t(2+n+3*q): return -1
  for i in 0..<n:
    if input[2+i] < -1_000_000 or input[2+i] > 1_000_000: return -1
  for u in 0..<q:
    let base = 2+n+3*u
    if input[base] < 0 or input[base] >= rawN or input[base+1] < input[base] or input[base+1] >= rawN or
        input[base+2] < -1_000_000 or input[base+2] > 1_000_000: return -1
  let bytes = n*8
  if output == nil or capacity < csize_t(bytes): return -2
  var diff: array[65, int64]
  diff[0] = input[2]
  for i in 1..<n: diff[i] = input[2+i] - input[2+i-1]
  for u in 0..<q:
    let base = 2+n+3*u
    let left = int(input[base])
    let right = int(input[base+1])
    let delta = input[base+2]
    diff[left] += delta
    diff[right+1] -= delta
  var current = diff[0]
  putI64Le(output, 0, current)
  for i in 1..<n:
    current += diff[i]
    putI64Le(output, i*8, current)
  int64(bytes)
