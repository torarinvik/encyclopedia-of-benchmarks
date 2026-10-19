# Modified derivative of cBench automotive_qsort1. Upstream directory notice, verbatim: “Matt wrote this using STL. It is GPL'ed.” The notice does not identify a GPL version. qsort.c copyright (C) 2002 Michael Ringgaard. All rights reserved.
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 1. Redistributions of source code must retain the above copyright notice, this
#    list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
# 3. Neither the name of the project nor the names of its contributors may be
#    used to endorse or promote products derived from this software without
#    specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
# ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

import std/math

const MaxPoints = 128
const MaxCoord = 1_000_000'i64

proc shortsort(ids: var array[MaxPoints, int], score: array[MaxPoints, float64], lo, hi: int) =
  var endIndex = hi
  while endIndex > lo:
    var maximum = lo
    for p in lo + 1 .. endIndex:
      if score[ids[p]] > score[ids[maximum]]: maximum = p
    swap(ids[maximum], ids[endIndex])
    dec endIndex

proc sortRange(ids: var array[MaxPoints, int], score: array[MaxPoints, float64], lo, hi: int) =
  if hi <= lo: return
  if hi - lo + 1 <= 8:
    shortsort(ids, score, lo, hi)
    return
  swap(ids[lo + (hi - lo + 1) div 2], ids[lo])
  var loguy = lo
  var higuy = hi + 1
  while true:
    inc loguy
    while loguy <= hi and score[ids[loguy]] <= score[ids[lo]]: inc loguy
    dec higuy
    while higuy > lo and score[ids[higuy]] >= score[ids[lo]]: dec higuy
    if higuy < loguy: break
    swap(ids[loguy], ids[higuy])
  swap(ids[lo], ids[higuy])
  if higuy > lo + 1: sortRange(ids, score, lo, higuy - 1)
  if loguy < hi: sortRange(ids, score, loguy, hi)

proc cbench_automotive_qsort1*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64 {.cdecl, exportc: "cbench_automotive_qsort1".} =
  if values.isNil or length < 4 or length > csize_t(385): return -1
  let nValue = values[0]
  if nValue < 1 or nValue > int64(MaxPoints) or length != csize_t(1 + 3 * nValue): return -1
  let n = int(nValue)
  var coords: array[MaxPoints, array[3, int32]]
  var ids: array[MaxPoints, int]
  var score: array[MaxPoints, float64]
  var radii: array[MaxPoints, int64]
  for i in 0 ..< n:
    var sum = 0'i64
    for a in 0 ..< 3:
      let v = values[1 + 3*i + a]
      if v < -MaxCoord or v > MaxCoord: return -1
      coords[i][a] = int32(v); sum += v*v
    for j in 0 ..< i: if radii[j] == sum: return -1
    radii[i] = sum; ids[i] = i
    score[i] = sqrt(float64(coords[i][0])*float64(coords[i][0]) + float64(coords[i][1])*float64(coords[i][1]) + float64(coords[i][2])*float64(coords[i][2]))
  if output.isNil or outputCapacity < csize_t(12*n): return -2
  sortRange(ids, score, 0, n-1)
  var staged: array[MaxPoints*12, uint8]
  for r in 0 ..< n:
    for a in 0 ..< 3:
      let bits = cast[uint32](coords[ids[r]][a])
      for b in 0 ..< 4: staged[12*r+4*a+b] = uint8((bits shr (8*b)) and 255)
  for i in 0 ..< 12*n: output[i] = staged[i]
  int64(12*n)
