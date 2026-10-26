#[
  Copyright (c) 1999 Takehiro TOMINAGA

  This library is free software; you can redistribute it and/or
  modify it under the terms of the GNU Library General Public
  License as published by the Free Software Foundation; either
  version 2 of the License, or (at your option) any later version.

  This library is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
  Library General Public License for more details.

  You should have received a copy of the GNU Library General Public
  License along with this library; if not, write to the
  Free Software Foundation, Inc., 59 Temple Place - Suite 330,
  Boston, MA 02111-1307, USA.
]#
import math

const SampleCount = 511
const WindowCount = 256
const InputCount = 767
const MaxInputLength = 768
const BandCount = 32
const OutputBytes = 256
const Pi = 3.14159265358979323846264338327950288
const SOffsets = [334,398,462,14,78,142,206,16,80,144,208,272,336,400,464]
const TOffsets = [176,112,48,496,432,368,304,494,430,366,302,238,174,110,46]

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[offset + byte] = uint8((bits shr (8 * byte)) and 255'u64)

proc roundQ1000(value: float64): int64 =
  let scaled = value * 1000.0
  let magnitude = if scaled < 0.0: -scaled else: scaled
  let rounded = int64(magnitude + 0.5)
  if scaled < 0.0: -rounded else: rounded

proc valid(input: ptr UncheckedArray[int64], length: int): bool =
  if length != InputCount: return false
  for i in 0 ..< SampleCount:
    if input[i] < -32768 or input[i] > 32767: return false
  for i in 0 ..< WindowCount:
    let value = input[SampleCount + i]
    if value < -4500000 or value > 36000000: return false
  if input[SampleCount] <= 25000000: return false
  for i in countup(8, WindowCount - 1, 16):
    if input[SampleCount + i] <= 25000000: return false
  true

proc windowSubband(input: ptr UncheckedArray[int64], window: var array[WindowCount, float64]): array[BandCount, float64] =
  let maximum = window[248]
  var mmax: array[31, float64]
  var mm: array[16, array[31, float64]]
  var wp = 0
  var wr = 0
  var w = window[wp]; inc wp
  mmax[15] = w / maximum
  for _ in 0 ..< 7:
    window[wr] = window[wp] / w; inc wr; inc wp
  for i in countdown(14, 0):
    w = window[wp]; inc wp
    mmax[i] = w / maximum
    mmax[30 - i] = w / maximum
    for _ in 0 ..< 15:
      window[wr] = window[wp] / w; inc wr; inc wp
  inc wp
  for _ in 0 ..< 7:
    window[wr] = window[wp] / maximum; inc wr; inc wp
  for i in countdown(15, 0):
    for k in 1 ..< 32:
      mm[i][k - 1] = cos(float64((2 * i + 1) * k) * Pi / 64.0) * mmax[k - 1]

  var inner: array[31, float64]
  var coeff = 0
  var t = float64(input[255])
  t += float64(input[223] - input[287]) * window[coeff]; inc coeff
  t += float64(input[191] + input[319]) * window[coeff]; inc coeff
  t += float64(input[159] - input[351]) * window[coeff]; inc coeff
  t += float64(input[127] + input[383]) * window[coeff]; inc coeff
  t += float64(input[95] - input[415]) * window[coeff]; inc coeff
  t += float64(input[63] + input[447]) * window[coeff]; inc coeff
  t += float64(input[31] - input[479]) * window[coeff]; inc coeff
  inner[15] = t
  for i in countdown(14, 0):
    var s = float64(input[270 - i])
    t = float64(input[240 + i])
    for k in 0 ..< 15:
      w = window[coeff]; inc coeff
      let si = SOffsets[k] + (if k < 7: -i else: i)
      let ti = TOffsets[k] + (if k < 7: i else: -i)
      let sv = float64(input[si]) * w
      let tv = float64(input[ti]) * w
      if k >= 11: s -= sv else: s += sv
      if k >= 7 and k < 11: t -= tv else: t += tv
    inner[30 - i] = s
    inner[i] = t
  var s = float64(input[239])
  s += float64(input[175]) * window[coeff]; inc coeff
  s += float64(input[111]) * window[coeff]; inc coeff
  s += float64(input[47]) * window[coeff]; inc coeff
  s -= float64(input[303]) * window[coeff]; inc coeff
  s -= float64(input[367]) * window[coeff]; inc coeff
  s -= float64(input[431]) * window[coeff]; inc coeff
  s -= float64(input[495]) * window[coeff]

  var bands: array[BandCount, float64]
  for i in countdown(15, 0):
    var s0 = s
    var s1 = t * mm[i][0]
    var at = 1
    for _ in 0 ..< 15:
      s0 += mm[i][at] * inner[at]; inc at
      s1 += mm[i][at] * inner[at]; inc at
    bands[i] = s0 + s1
    bands[31 - i] = s0 - s1
  bands

proc cbench_consumer_lame_window_subband*(input: ptr UncheckedArray[int64], inputLength: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "cbench_consumer_lame_window_subband".} =
  if input == nil or inputLength < 1 or inputLength > MaxInputLength.csize_t: return -1
  if not valid(input, int(inputLength)): return -1
  var window: array[WindowCount, float64]
  for i in 0 ..< WindowCount: window[i] = float64(input[SampleCount + i]) / 1_000_000_000.0
  let bands = windowSubband(input, window)
  var staged: array[BandCount, int64]
  for i in 0 ..< BandCount: staged[i] = roundQ1000(bands[i])
  if output == nil or outputCapacity < OutputBytes.csize_t: return -2
  for i in 0 ..< BandCount: storeI64Le(output, 8 * i, staged[i])
  OutputBytes.int64
