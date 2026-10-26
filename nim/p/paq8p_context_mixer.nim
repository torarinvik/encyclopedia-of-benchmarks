## Copyright (C) 2008 Matt Mahoney, Serge Osnach, Alexander Ratushnyak, Bill Pettis, Przemyslaw Skibinski, Matthew Fite, wowtiger, Andrew Paterson, Jan Ondrus, Andreas Morphis, Pavel L. Holoborodko, KZ.
## This program is free software; redistribute and/or modify it under the GNU
## General Public License as published by the Free Software Foundation, either
## version 2 or (at your option) any later version. It is provided without any
## warranty, including merchantability or fitness for a particular purpose.
## See https://www.gnu.org/licenses/ for details.
const St = [1'i32,2,3,6,10,16,27,45,73,120,194,310,488,747,1101,1546,2047,2549,2994,3348,3607,3785,3901,3975,4022,4050,4068,4079,4085,4089,4092,4093,4094]

proc squash(d0: int32): int32 =
  if d0 > 2047: return 4095
  if d0 < -2047: return 0
  let w = d0 and 127
  let d = (d0 shr 7) + 16
  (St[int(d)] * (128-w) + St[int(d)+1] * w + 64) shr 7

proc makeStretch(): array[4096, int32] =
  var t: array[4096, int32]
  var pi = 0
  for x in -2047'i32 .. 2047'i32:
    let endIndex = squash(x)
    for j in pi .. int(endIndex): t[j] = x
    pi = int(endIndex) + 1
  t[4095] = 2047
  t

proc dot8(t, w: array[8, int32]): int32 =
  var total = 0'i32
  for i in countup(0, 6, 2): total += (t[i]*w[i] + t[i+1]*w[i+1]) shr 8
  total

proc train8(t: array[8, int32], w: var array[8, int32], err: int32) =
  for i in 0 ..< 8:
    var value = w[i] + (((t[i] * err * 2 shr 16) + 1) shr 1)
    if value < -32768: value = -32768
    if value > 32767: value = 32767
    w[i] = value

proc paq8p_context_mixer*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc.} =
  if input == nil or length < 12 or length > 177: return -1
  let count = input[0]
  if count < 1 or count > 16 or length != csize_t(1 + count * 11): return -1
  var features: array[16, array[8, int32]]
  var contexts0, contexts1, targets: array[16, int32]
  var p = 1
  for s in 0 ..< int(count):
    if input[p] < 0 or input[p] > 1 or input[p+1] < 0 or input[p+1] > 1 or input[p+2] < 0 or input[p+2] > 1: return -1
    contexts0[s] = int32(input[p]); contexts1[s] = int32(input[p+1]); targets[s] = int32(input[p+2]); p += 3
    for j in 0 ..< 8:
      if input[p] < -2047 or input[p] > 2047: return -1
      features[s][j] = int32(input[p]); inc p
  let needed = int(count) * 2
  if output == nil or capacity < csize_t(needed): return -2
  let stretch = makeStretch()
  var outer: array[4, array[8, int32]]
  var inner: array[8, int32]
  for j in 0 ..< 8: inner[j] = 32767
  var previousInner: array[8, int32]
  var previousPrediction = 2048'i32
  var previousTarget = 0'i32
  for s in 0 ..< int(count):
    if s > 0: train8(previousInner, inner, ((previousTarget shl 12)-previousPrediction)*7)
    let ctx = [int(contexts0[s]), 2 + int(contexts1[s])]
    var model: array[2, int32]
    for k in 0 ..< 2: model[k] = squash(dot8(features[s], outer[ctx[k]]) shr 5)
    let x = [stretch[int(model[0])], stretch[int(model[1])], 0'i32,0,0,0,0,0]
    let prediction = squash(dot8(x, inner) shr 8)
    output[s*2] = uint8(prediction and 255); output[s*2+1] = uint8((prediction shr 8) and 255)
    for k in 0 ..< 2: train8(features[s], outer[ctx[k]], ((targets[s] shl 12)-model[k])*7)
    previousInner = x; previousPrediction = prediction; previousTarget = targets[s]
  int64(needed)
