## Copyright 1992 by Stichting Mathematisch Centrum, Amsterdam, The Netherlands.
##
## All Rights Reserved
##
## Permission to use, copy, modify, and distribute this software and its
## documentation for any purpose and without fee is hereby granted, provided
## that the above copyright notice appear in all copies and that both that
## copyright notice and this permission notice appear in supporting
## documentation, and that the names of Stichting Mathematisch Centrum or CWI
## not be used in advertising or publicity pertaining to distribution of the
## software without specific, written prior permission.
##
## STICHTING MATHEMATISCH CENTRUM DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS
## SOFTWARE, INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS,
## IN NO EVENT SHALL STICHTING MATHEMATISCH CENTRUM BE LIABLE FOR ANY SPECIAL,
## INDIRECT OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
## LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE
## OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
## PERFORMANCE OF THIS SOFTWARE.

const IndexTable: array[16, int32] = [-1'i32, -1, -1, -1, 2, 4, 6, 8, -1, -1, -1, -1, 2, 4, 6, 8]
const StepTable: array[89, int32] = [
  7'i32, 8, 9, 10, 11, 12, 13, 14, 16, 17, 19, 21, 23, 25, 28, 31,
  34, 37, 41, 45, 50, 55, 60, 66, 73, 80, 88, 97, 107, 118, 130,
  143, 157, 173, 190, 209, 230, 253, 279, 307, 337, 371, 408, 449,
  494, 544, 598, 658, 724, 796, 876, 963, 1060, 1166, 1282, 1411,
  1552, 1707, 1878, 2066, 2272, 2499, 2749, 3024, 3327, 3660, 4026,
  4428, 4871, 5358, 5894, 6484, 7132, 7845, 8630, 9493, 10442, 11487,
  12635, 13899, 15289, 16818, 18500, 20350, 22385, 24623, 27086, 29794,
  32767
]

proc clampIndex(value: int32): int32 =
  if value < 0: return 0
  if value > 88: return 88
  value

proc clampSample(value: int32): int32 =
  if value < -32768: return -32768
  if value > 32767: return 32767
  value

proc encodeOne(sample: int32, predictor, index: var int32): uint8 =
  var step = StepTable[int(index)]
  var diff = sample - predictor
  let sign = if diff < 0: 8'i32 else: 0'i32
  if sign != 0: diff = -diff
  var code = 0'i32
  var change = step shr 3
  if diff >= step:
    code = 4
    diff -= step
    change += step
  step = step shr 1
  if diff >= step:
    code = code or 2
    diff -= step
    change += step
  step = step shr 1
  if diff >= step:
    code = code or 1
    change += step
  predictor = clampSample(predictor + (if sign != 0: -change else: change))
  code = code or sign
  index = clampIndex(index + IndexTable[int(code)])
  uint8(code)

proc decodeOne(code: uint8, predictor, index: var int32): int32 =
  let step = StepTable[int(index)]
  index = clampIndex(index + IndexTable[int(code)])
  let magnitude = int32(code and 7)
  var change = step shr 3
  if (magnitude and 4) != 0: change += step
  if (magnitude and 2) != 0: change += step shr 1
  if (magnitude and 1) != 0: change += step shr 2
  predictor = clampSample(predictor + (if (code and 8) != 0: -change else: change))
  predictor

proc lac_adpcm*(input: ptr UncheckedArray[int64], inputLength: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "lac_adpcm".} =
  if input.isNil or inputLength < 2 or inputLength > 258: return -1
  let mode = input[0]
  let count = input[1]
  if mode == 1:
    if count < 0 or count > 256 or inputLength != csize_t(count) + 2: return -1
    for i in 0 ..< int(count):
      if input[i + 2] < -32768 or input[i + 2] > 32767: return -1
  elif mode == 2:
    if count < 0 or count > 128 or inputLength != csize_t(count) + 2: return -1
    for i in 0 ..< int(count):
      if input[i + 2] < 0 or input[i + 2] > 255: return -1
  else:
    return -1

  let n = int(count)
  let required = if mode == 1: (n + 1) div 2 else: n * 4
  if required == 0: return 0
  if output.isNil or outputCapacity < csize_t(required): return -2
  var predictor = 0'i32
  var index = 0'i32
  if mode == 1:
    for i in 0 ..< n:
      let code = encodeOne(int32(input[i + 2]), predictor, index)
      if (i and 1) == 0: output[i div 2] = code shl 4
      else: output[i div 2] = output[i div 2] or code
  else:
    for i in 0 ..< n:
      let packed = uint8(input[i + 2])
      for half in 0 ..< 2:
        let code = if half == 0: packed shr 4 else: packed and 15
        let sample = decodeOne(code, predictor, index)
        let bits = cast[uint16](int16(sample))
        let position = (i * 2 + half) * 2
        output[position] = uint8(bits and 255)
        output[position + 1] = uint8(bits shr 8)
  int64(required)
