proc reservoirXfalling(top: int64, count: int): int64 =
  result = 1
  for i in 0 ..< count: result *= top-int64(i)

proc reservoirXgcd(aValue, bValue: int64): int64 =
  var a = aValue
  var b = bValue
  while b != 0:
    let remainder = a mod b
    a = b
    b = remainder
  a

proc reservoir_sampling_algorithm_x*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "reservoir_sampling_algorithm_x".} =
  if input == nil or length < 3 or length > 49: return -1
  if input[0] < 1 or input[0] > 16 or input[1] < 1 or input[1] > 8: return -1
  let n = int(input[0])
  let k = int(input[1])
  if (k and (k-1)) != 0 or k > n or int(length) != 2+n+2*(n-k): return -1
  for i in 0 ..< n:
    if input[2+i] < -1000000 or input[2+i] > 1000000: return -1
  for i in 2+n ..< int(length):
    if input[i] < 0 or input[i] > 4294967295'i64: return -1
  if output == nil or capacity < csize_t(8*k): return -2
  var sample: array[8, int64]
  for i in 0 ..< k: sample[i] = input[2+i]
  var processed = k
  var attempt = 0
  while processed < n:
    let draw = input[2+n+2*attempt]
    let slotDraw = input[2+n+2*attempt+1]
    inc attempt
    var numerator = reservoirXfalling(int64(processed), k)
    var denominator = reservoirXfalling(int64(processed+1), k)
    let divisor = reservoirXgcd(numerator, denominator)
    numerator = numerator div divisor
    denominator = denominator div divisor
    let maxSkip = n-processed-1
    var selected = 0
    var found = false
    for skip in 0 .. maxSkip:
      if numerator*4294967297'i64 <= (draw+1)*denominator:
        selected = skip
        found = true
        break
      if skip < maxSkip:
        let top = int64(processed+skip+1)
        numerator *= top+1-int64(k)
        denominator *= top+1
        let reduceBy = reservoirXgcd(numerator, denominator)
        numerator = numerator div reduceBy
        denominator = denominator div reduceBy
    if not found: break
    let slot = int(slotDraw mod int64(k))
    sample[slot] = input[2+processed+selected]
    processed += selected+1
  for i in 0 ..< k:
    var bits = cast[uint64](sample[i])
    for j in 0 ..< 8:
      output[8*i+j] = uint8(bits and 255'u64)
      bits = bits shr 8
  int64(8*k)
