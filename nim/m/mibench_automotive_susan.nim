#######################################################################
# SUSAN Version 2l by Stephen Smith
# Oxford Centre for Functional Magnetic Resonance Imaging of the Brain,
# Department of Clinical Neurology, Oxford University, Oxford, UK
# (Previously in Computer Vision and Image Processing Group - now
# Computer Vision and Electro Optics Group - DERA Chertsey, UK)
# Email:    steve@fmrib.ox.ac.uk
# WWW:      http://www.fmrib.ox.ac.uk/~steve
# (C) Crown Copyright (1995-1999), Defence Evaluation and Research Agency,
# Farnborough, Hampshire, GU14 6TD, UK
# DERA WWW site:
# http://www.dera.gov.uk/
# DERA Computer Vision and Electro Optics Group WWW site:
# http://www.dera.gov.uk/imageprocessing/dera/group_home.html
# DERA Computer Vision and Electro Optics Group point of contact:
# Dr. John Savage, jtsavage@dera.gov.uk, +44 1344 633203
# A UK patent has been granted: "Method for digitally processing
# images to determine the position of edges and/or corners therein for
# guidance of unmanned vehicle", UK Patent 2272285. Proprietor:
# Secretary of State for Defence, UK. 15 January 1997
#
# This code is issued for research purposes only and remains the
# property of the UK Secretary of State for Defence. This code must
# not be passed on without this header information being kept
# intact. This code must not be sold.
#######################################################################
import math

const MinSide = 15
const MaxSide = 16
const MaxParseableInputLength = 258
const MaskRadius = 7

proc reflectIndex(index: int, side: int): int =
  if index < 0: return -index - 1
  if index >= side: return 2 * side - index - 1
  index

proc setupWeights(brightness: var array[511, int], distance: var array[225, int]) =
  for slot in 0 ..< 511:
    let difference = slot - 255
    var temp = float32(difference) / 20'f32
    temp *= temp
    temp = float32(100.0 * exp(-float64(temp)))
    brightness[slot] = int(temp)
  var index = 0
  for dy in -MaskRadius .. MaskRadius:
    for dx in -MaskRadius .. MaskRadius:
      let squaredDistance = float32(dx * dx + dy * dy)
      distance[index] = int(100.0 * exp(float64(squaredDistance) / -16.0))
      inc index

proc medianEight(image: array[256, uint8], side, y, x: int): uint8 =
  var values: array[8, int]
  var count = 0
  for dy in -1 .. 1:
    for dx in -1 .. 1:
      if dx == 0 and dy == 0: continue
      let sy = reflectIndex(y + dy, side)
      let sx = reflectIndex(x + dx, side)
      values[count] = int(image[sy * side + sx])
      inc count
  for pass in 0 ..< 7:
    for index in 0 ..< 7 - pass:
      if values[index] > values[index + 1]:
        swap(values[index], values[index + 1])
  uint8((values[3] + values[4]) div 2)

proc mibenchAutomotiveSusan(input: ptr UncheckedArray[int64], inputLength: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "mibench_automotive_susan".} =
  if input == nil or inputLength < 2 or inputLength > MaxParseableInputLength.csize_t: return -1
  if input[0] < MinSide.int64 or input[0] > MaxSide.int64: return -1
  let side = int(input[0])
  let pixelCount = side * side
  if inputLength != csize_t(pixelCount + 1): return -1
  var image: array[256, uint8]
  for index in 0 ..< pixelCount:
    let pixel = input[index + 1]
    if pixel < 0 or pixel > 255: return -1
    image[index] = uint8(pixel)
  if output == nil or int(outputCapacity) < pixelCount: return -2

  var brightness: array[511, int]
  var distance: array[225, int]
  setupWeights(brightness, distance)
  for y in 0 ..< side:
    for x in 0 ..< side:
      let center = int(image[y * side + x])
      var area = 0
      var total = 0
      var maskIndex = 0
      for dy in -MaskRadius .. MaskRadius:
        let sy = reflectIndex(y + dy, side)
        for dx in -MaskRadius .. MaskRadius:
          let sx = reflectIndex(x + dx, side)
          let pixel = int(image[sy * side + sx])
          let contribution = distance[maskIndex] * brightness[center - pixel + 255]
          area += contribution
          total += contribution * pixel
          inc maskIndex
      let denominator = area - 10000
      output[y * side + x] = if denominator == 0:
        medianEight(image, side, y, x)
      else:
        uint8((total - center * 10000) div denominator)
  int64(pixelCount)
