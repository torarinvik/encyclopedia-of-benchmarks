# Based on Don Cross <dcross@intersrv.com>'s public-domain fft_float (intersrv.com/~dcross/fft.html).
# Modified for the bounded float64-slice ABI; binary32 work-array semantics retained.
import std/math

type InputPtr = ptr UncheckedArray[float64]
type OutputPtr = ptr UncheckedArray[float64]

proc transform(real: var array[16, float32], imag: var array[16, float32], n: int, inverse: bool) =
  var bits = 0
  var size = n
  while size > 1: bits += 1; size = size shr 1
  for i in 0 ..< n:
    var source = i
    var reverse = 0
    for _ in 0 ..< bits: reverse = (reverse shl 1) or (source and 1); source = source shr 1
    if i < reverse: swap(real[i], real[reverse]); swap(imag[i], imag[reverse])
  let angleNum = (if inverse: -2.0 else: 2.0) * PI
  var blockEnd = 1
  var block = 2
  while block <= n:
    let delta = angleNum / float64(block)
    let sm2 = sin(-2.0 * delta); let sm1 = sin(-delta)
    let cm2 = cos(-2.0 * delta); let cm1 = cos(-delta); let w = 2.0 * cm1
    var start = 0
    while start < n:
      var ar2 = cm2; var ar1 = cm1; var ai2 = sm2; var ai1 = sm1
      for offset in 0 ..< blockEnd:
        let ar0 = w * ar1 - ar2; ar2 = ar1; ar1 = ar0
        let ai0 = w * ai1 - ai2; ai2 = ai1; ai1 = ai0
        let first = start + offset; let second = first + blockEnd
        let tr = ar0 * float64(real[second]) - ai0 * float64(imag[second])
        let ti = ar0 * float64(imag[second]) + ai0 * float64(real[second])
        real[second] = float32(float64(real[first]) - tr); imag[second] = float32(float64(imag[first]) - ti)
        real[first] = float32(float64(real[first]) + tr); imag[first] = float32(float64(imag[first]) + ti)
      start += block
    blockEnd = block
    block *= 2
  if inverse:
    for i in 0 ..< n: real[i] = float32(float64(real[i]) / float64(n)); imag[i] = float32(float64(imag[i]) / float64(n))

proc mibench_telecomm_fft*(input: InputPtr, length: csize_t, output: OutputPtr,
    outputCapacity: csize_t): int64 {.cdecl, exportc: "mibench_telecomm_fft".} =
  if input == nil or length < 6 or length > 34: return -1
  let nd = input[0]; let inverse = input[1]
  if nd != nd or inverse != inverse or nd != floor(nd) or inverse != floor(inverse)
      or nd < 2.0 or nd > 16.0 or (inverse != 0.0 and inverse != 1.0): return -1
  let n = int(nd)
  if (n and (n - 1)) != 0 or length != csize_t(2 + 2 * n): return -1
  for i in 2 ..< int(length):
    if input[i] != input[i] or input[i] < -8.0 or input[i] > 8.0: return -1
  let required = 2 * n
  if output == nil or outputCapacity < csize_t(required): return -2
  var real, imag: array[16, float32]
  for i in 0 ..< n: real[i] = float32(input[2 + i]); imag[i] = float32(input[2 + n + i])
  transform(real, imag, n, inverse != 0.0)
  var staged: array[32, float64]
  for i in 0 ..< n: staged[2 * i] = float64(real[i]); staged[2 * i + 1] = float64(imag[i])
  for i in 0 ..< required: output[i] = staged[i]
  int64(required)
