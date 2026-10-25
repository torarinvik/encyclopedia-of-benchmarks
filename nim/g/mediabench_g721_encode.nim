## This source code is a product of Sun Microsystems, Inc. and is provided
## for unrestricted use. Users may copy or modify this source code without charge.
##
## SUN SOURCE CODE IS PROVIDED AS IS WITH NO WARRANTIES OF ANY KIND INCLUDING
## THE WARRANTIES OF DESIGN, MERCHANTIBILITY AND FITNESS FOR A PARTICULAR
## PURPOSE, OR ARISING FROM A COURSE OF DEALING, USAGE OR TRADE PRACTICE.
##
## Sun source code is provided with no support and without any obligation on
## the part of Sun Microsystems, Inc. to assist in its use, correction,
## modification or enhancement.
##
## SUN MICROSYSTEMS, INC. SHALL HAVE NO LIABILITY WITH RESPECT TO THE
## INFRINGEMENT OF COPYRIGHTS, TRADE SECRETS OR ANY PATENTS BY THIS SOFTWARE
## OR ANY PART THEREOF.
##
## In no event will Sun Microsystems, Inc. be liable for any lost revenue
## or profits or other special, indirect and consequential damages, even if
## Sun has been advised of the possibility of such damages.
##
## Sun Microsystems, Inc.
## 2550 Garcia Avenue
## Mountain View, California 94043

const MaxSamples = 16
const Power2: array[15, int64] = [1'i64,2,4,8,16,32,64,128,256,512,1024,2048,4096,8192,16384]
const Qtab: array[7, int64] = [-124'i64,80,178,246,300,349,400]
const Dqlntab: array[16, int64] = [-2048'i64,4,135,213,273,323,373,425,425,373,323,273,213,135,4,-2048]
const Witab: array[16, int64] = [-12'i64,18,41,64,112,198,355,1122,1122,355,198,112,64,41,18,-12]
const Fitab: array[16, int64] = [0'i64,0,0,512,512,512,1536,3584,3584,1536,512,512,512,0,0,0]

type State = object
  yl, yu, dms, dml, ap: int64
  a: array[2, int64]
  b: array[6, int64]
  pk: array[2, int64]
  dq: array[6, int64]
  sr: array[2, int64]
  td: int64

proc wrap16(value: int64): int64 =
  let low = cast[uint64](value) and 0xffff'u64
  if low >= 0x8000'u64: int64(low) - 65536 else: int64(low)

proc qtable(value: int64, table: openArray[int64]): int64 =
  for item in table:
    if value < item: return int64(result)
    inc result

proc fmult(coefficient, encoded: int64): int64 =
  let magnitude = if coefficient > 0: coefficient else: ((-coefficient) and 0x1fff)
  let exponent = qtable(magnitude, Power2) - 6
  let mantissa = if magnitude == 0: 32'i64 elif exponent >= 0: magnitude shr int(exponent) else: magnitude shl int(-exponent)
  let productExponent = exponent + ((encoded shr 6) and 15) - 13
  let productMantissa = (mantissa * (encoded and 0o77) + 0x30) shr 4
  let value = if productExponent >= 0: (productMantissa shl int(productExponent)) and 0x7fff else: productMantissa shr int(-productExponent)
  if (coefficient xor encoded) < 0: -value else: value

proc predictorZero(s: State): int64 =
  result = fmult(s.b[0] shr 2, s.dq[0])
  for i in 1 ..< 6: result += fmult(s.b[i] shr 2, s.dq[i])

proc predictorPole(s: State): int64 = fmult(s.a[1] shr 2, s.sr[1]) + fmult(s.a[0] shr 2, s.sr[0])

proc stepSize(s: State): int64 =
  if s.ap >= 256: return s.yu
  result = s.yl shr 6
  let difference = s.yu - result
  let weight = s.ap shr 2
  if difference > 0: result += (difference * weight) shr 6
  elif difference < 0: result += (difference * weight + 0x3f) shr 6

proc quantize(difference, step: int64): int64 =
  let magnitude = if difference < 0: -difference else: difference
  let exponent = qtable(magnitude shr 1, Power2)
  let mantissa = ((magnitude shl 7) shr int(exponent)) and 0x7f
  let normalized = ((exponent shl 7) + mantissa) - (step shr 2)
  let index = qtable(normalized, Qtab)
  if difference < 0: 15 - index elif index == 0: 15 else: index

proc reconstruct(sign, dqln, step: int64): int64 =
  let dql = dqln + (step shr 2)
  if dql < 0: return (if sign != 0: -32768 else: 0)
  let exponent = (dql shr 7) and 15
  let mantissa = 128 + (dql and 127)
  let value = (mantissa shl 7) shr int(14 - exponent)
  if sign != 0: value - 32768 else: value

proc abs64(value: int64): int64 = if value < 0: -value else: value

proc update(step, wi, fi, dq, sr, dqsez: int64, s: var State) =
  let magnitude = dq and 0x7fff
  let ylint = s.yl shr 15
  let ylfrac = (s.yl shr 10) and 0x1f
  let threshold1 = (32 + ylfrac) shl int(ylint)
  let threshold2 = if ylint > 9: 31'i64 shl 10 else: threshold1
  let dqthr = (threshold2 + (threshold2 shr 1)) shr 1
  let transition = s.td != 0 and magnitude > dqthr
  s.yu = wrap16(step + ((wi - step) shr 5))
  if s.yu < 544: s.yu = 544
  elif s.yu > 5120: s.yu = 5120
  s.yl += s.yu + ((-s.yl) shr 6)
  if transition:
    s.a = [0'i64, 0]
    s.b = [0'i64, 0, 0, 0, 0, 0]
  else:
    let pk0 = if dqsez < 0: 1'i64 else: 0
    let pks1 = pk0 xor s.pk[0]
    var a2p = s.a[1] - (s.a[1] shr 7)
    if dqsez != 0:
      let fa1 = if pks1 != 0: s.a[0] else: -s.a[0]
      if fa1 < -8191: a2p -= 0x100
      elif fa1 > 8191: a2p += 0xff
      else: a2p += fa1 shr 5
      if (pk0 xor s.pk[1]) != 0:
        if a2p <= -12160: a2p = -12288
        elif a2p >= 12416: a2p = 12288
        else: a2p -= 0x80
      elif a2p <= -12416: a2p = -12288
      elif a2p >= 12160: a2p = 12288
      else: a2p += 0x80
    a2p = wrap16(a2p)
    s.a[1] = a2p
    s.a[0] = wrap16(s.a[0] - (s.a[0] shr 8))
    if dqsez != 0: s.a[0] = wrap16(s.a[0] + (if pks1 == 0: 192 else: -192))
    let limit = 15360 - a2p
    if s.a[0] < -limit: s.a[0] = -limit
    elif s.a[0] > limit: s.a[0] = limit
    s.a[0] = wrap16(s.a[0])
    for i in 0 ..< 6:
      s.b[i] = wrap16(s.b[i] - (s.b[i] shr 8))
      if (dq and 0x7fff) != 0: s.b[i] = wrap16(s.b[i] + (if (dq xor s.dq[i]) >= 0: 128 else: -128))
  for i in countdown(5, 1): s.dq[i] = s.dq[i - 1]
  if magnitude == 0: s.dq[0] = if dq >= 0: 0x20 else: wrap16(0xfc20)
  else:
    let exponent = qtable(magnitude, Power2)
    let encoded = (exponent shl 6) + ((magnitude shl 6) shr int(exponent))
    s.dq[0] = wrap16(if dq >= 0: encoded else: encoded - 0x400)
  s.sr[1] = s.sr[0]
  if sr == 0: s.sr[0] = 0x20
  elif sr > 0:
    let exponent = qtable(sr, Power2)
    s.sr[0] = wrap16((exponent shl 6) + ((sr shl 6) shr int(exponent)))
  elif sr > -32768:
    let absolute = -sr
    let exponent = qtable(absolute, Power2)
    s.sr[0] = wrap16((exponent shl 6) + ((absolute shl 6) shr int(exponent)) - 0x400)
  else: s.sr[0] = wrap16(0xfc20)
  s.pk[1] = s.pk[0]
  s.pk[0] = if dqsez < 0: 1 else: 0
  s.td = if transition: 0 elif s.a[1] < -11776: 1 else: 0
  s.dms = wrap16(s.dms + ((fi - s.dms) shr 5))
  s.dml = wrap16(s.dml + (((fi shl 2) - s.dml) shr 7))
  if transition: s.ap = 256
  elif step < 1536 or s.td == 1 or abs64((s.dms shl 2) - s.dml) >= (s.dml shr 3): s.ap = wrap16(s.ap + ((0x200 - s.ap) shr 4))
  else: s.ap = wrap16(s.ap + ((-s.ap) shr 4))

proc initState(): State =
  result.yl = 34816; result.yu = 544; result.dms = 0; result.dml = 0; result.ap = 0; result.td = 0
  for i in 0 ..< 2: result.a[i] = 0; result.pk[i] = 0; result.sr[i] = 32
  for i in 0 ..< 6: result.b[i] = 0; result.dq[i] = 32

proc ulawToLinear(input: int64): int64 =
  let value = (not input) and 0xff
  var sample = ((value and 15) shl 3) + 0x84
  sample = sample shl int((value and 0x70) shr 4)
  if (value and 0x80) != 0: 0x84 - sample else: sample - 0x84

proc encodeOne(input: int64, s: var State): int64 =
  let sample = ulawToLinear(input) shr 2
  let sezi = wrap16(predictorZero(s))
  let sez = sezi shr 1
  let se = wrap16((sezi + predictorPole(s)) shr 1)
  let difference = wrap16(sample - se)
  let step = wrap16(stepSize(s))
  let code = quantize(difference, step)
  let dq = wrap16(reconstruct(code and 8, Dqlntab[int(code)], step))
  let sr = wrap16(if dq < 0: se - (dq and 0x3fff) else: se + dq)
  let dqsez = wrap16(sr + sez - se)
  update(step, Witab[int(code)] shl 5, Fitab[int(code)], dq, sr, dqsez, s)
  code

proc mediabench_g721_encode*(input: ptr UncheckedArray[int64], inputLength: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64 {.cdecl, exportc: "mediabench_g721_encode".} =
  if input == nil or inputLength < 1 or inputLength > MaxSamples + 1: return -1
  let countValue = input[0]
  if countValue < 0 or countValue > MaxSamples: return -1
  let count = int(countValue)
  if inputLength != csize_t(count + 1): return -1
  for i in 0 ..< count:
    if input[i + 1] < 0 or input[i + 1] > 255: return -1
  let required = (count + 1) div 2
  if required == 0: return 0
  if output == nil or outputCapacity < csize_t(required): return -2
  var state = initState()
  for i in 0 ..< count:
    let code = uint8(encodeOne(input[i + 1], state))
    if i mod 2 == 0: output[i div 2] = code
    else: output[i div 2] = output[i div 2] or (code shl 4)
  int64(required)
