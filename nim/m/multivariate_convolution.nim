const MaxK = 3
const MaxP = 32
const MaxInput = 69
const MaxOutput = 256
const Mod = 998_244_353'i64
proc storeLe(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for b in 0 ..< 8: output[offset + b] = uint8((bits shr (8*b)) and 255'u64)
proc multivariate_convolution*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "multivariate_convolution".} =
  if input == nil or length < 1 or length > csize_t(MaxInput): return -1
  let k0 = input[0]
  if k0 < 0 or k0 > MaxK: return -1
  let k = int(k0)
  if int(length) < 1 + k: return -1
  var dims: array[MaxK, int]
  var p = 1
  for axis in 0 ..< k:
    let d0 = input[1 + axis]
    if d0 < 2 or d0 > MaxP or p > MaxP div int(d0): return -1
    dims[axis] = int(d0); p *= dims[axis]
  if int(length) != 1 + k + 2*p: return -1
  let start = 1 + k
  for q in start ..< int(length):
    if input[q] < 0 or input[q] >= Mod: return -1
  let bytes = 8*p
  if bytes > MaxOutput: return -1
  if output == nil or int(capacity) < bytes: return -2
  var a, b, result: array[MaxP, int64]
  for i in 0 ..< p: a[i] = input[start+i]; b[i] = input[start+p+i]
  for i in 0 ..< p:
    for j in 0 ..< p:
      var target = 0; var stride = 1; var valid = true
      for axis in 0 ..< k:
        let d = dims[axis]; let sum = (i div stride) mod d + (j div stride) mod d
        if sum >= d: valid = false; break
        target += sum * stride; stride *= d
      if valid: result[target] = (result[target] + a[i] * b[j]) mod Mod
  for i in 0 ..< p: storeLe(output, 8*i, result[i])
  int64(bytes)
