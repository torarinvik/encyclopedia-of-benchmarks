const MaxK = 3
const MaxP = 32
const MaxInput = 70
const MaxOutput = 256
proc isPrime(p: int): bool =
  if p < 2: return false
  var d = 2
  while d*d <= p:
    if p mod d == 0: return false
    inc d
  true
proc storeLe(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for b in 0 ..< 8: output[offset+b] = uint8((bits shr (8*b)) and 255'u64)
proc multivariate_convolution_cyclic*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "multivariate_convolution_cyclic".} =
  if input == nil or length < 2 or length > csize_t(MaxInput): return -1
  let p0 = input[0]; let k0 = input[1]
  if p0 < 2 or p0 > 97 or not isPrime(int(p0)) or k0 < 0 or k0 > MaxK: return -1
  let p = int(p0); let k = int(k0)
  if int(length) < 2 + k: return -1
  var dims: array[MaxK, int]; var product = 1
  for axis in 0 ..< k:
    let d0 = input[2+axis]
    if d0 < 2 or d0 > MaxP or (p-1) mod int(d0) != 0 or product > MaxP div int(d0): return -1
    dims[axis] = int(d0); product *= dims[axis]
  let start = 2 + k
  if int(length) != start + 2*product: return -1
  for q in start ..< int(length):
    if input[q] < 0 or input[q] >= p0: return -1
  let bytes = 8*product
  if bytes > MaxOutput: return -1
  if output == nil or int(capacity) < bytes: return -2
  var a, b, result: array[MaxP, int64]
  for i in 0 ..< product: a[i] = input[start+i]; b[i] = input[start+product+i]
  for i in 0 ..< product:
    for j in 0 ..< product:
      var target = 0; var stride = 1
      for axis in 0 ..< k:
        let d = dims[axis]; let sum = ((i div stride) mod d + (j div stride) mod d) mod d
        target += sum * stride; stride *= d
      result[target] = (result[target] + a[i] * b[j]) mod p0
  for i in 0 ..< product: storeLe(output, 8*i, result[i])
  int64(bytes)
