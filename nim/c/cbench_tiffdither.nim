## Copyright (c) 1988-1997 Sam Leffler
## Copyright (c) 1991-1997 Silicon Graphics, Inc.
##
## Permission to use, copy, modify, distribute, and sell this software and
## its documentation for any purpose is hereby granted without fee, provided
## that (i) the above copyright notices and this permission notice appear in
## all copies of the software and related documentation, and (ii) the names of
## Sam Leffler and Silicon Graphics may not be used in any advertising or
## publicity relating to the software without the specific, prior written
## permission of Sam Leffler and Silicon Graphics.
##
## THE SOFTWARE IS PROVIDED "AS-IS" AND WITHOUT WARRANTY OF ANY KIND,
## EXPRESS, IMPLIED OR OTHERWISE, INCLUDING WITHOUT LIMITATION, ANY
## WARRANTY OF MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE.
##
## IN NO EVENT SHALL SAM LEFFLER OR SILICON GRAPHICS BE LIABLE FOR
## ANY SPECIAL, INCIDENTAL, INDIRECT OR CONSEQUENTIAL DAMAGES OF ANY KIND,
## OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS,
## WHETHER OR NOT ADVISED OF THE POSSIBILITY OF DAMAGE, AND ON ANY THEORY OF
## LIABILITY, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE
## OF THIS SOFTWARE.

const MaxWidth = 32
const MaxHeight = 16
const MaxPixels = MaxWidth * MaxHeight
const MaxOutputBytes = 60

proc truncDiv(value, divisor: int): int =
  if value < 0: -((-value) div divisor) else: value div divisor

proc cbench_tiffdither*(input: ptr UncheckedArray[int64], inputLength: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "cbench_tiffdither".} =
  if input.isNil or inputLength < 5 or inputLength > 515: return -1
  if input[0] < 1 or input[0] > MaxWidth or input[1] < 2 or input[1] > MaxHeight or
      input[2] < 0 or input[2] > 255: return -1
  let width = int(input[0])
  let height = int(input[1])
  let threshold = int(input[2])
  let pixelCount = width * height
  if inputLength != csize_t(3 + pixelCount): return -1

  var work: array[MaxPixels, int16]
  for i in 0 ..< pixelCount:
    if input[i + 3] < 0 or input[i + 3] > 255: return -1
    work[i] = int16(input[i + 3])

  let rowBytes = (width + 7) div 8
  let outputSize = rowBytes * (height - 1)
  if output.isNil or outputCapacity < csize_t(outputSize): return -2
  var staged: array[MaxOutputBytes, uint8]

  for y in 0 ..< height - 1:
    let lastLine = y + 2 == height
    for x in 0 ..< width:
      let at = y * width + x
      var value = int(work[at])
      if value < 0: value = 0
      elif value > 255: value = 255
      if value > threshold:
        staged[y * rowBytes + x div 8] = staged[y * rowBytes + x div 8] or
          uint8(0x80 shr (x mod 8))
        value -= 255

      if x + 1 < width:
        work[at + 1] = int16(int(work[at + 1]) + truncDiv(value * 7, 16))
      if not lastLine:
        if x > 0:
          work[at + width - 1] = int16(int(work[at + width - 1]) + truncDiv(value * 3, 16))
        work[at + width] = int16(int(work[at + width]) + truncDiv(value * 5, 16))
        if x + 1 < width:
          work[at + width + 1] = int16(int(work[at + width + 1]) + truncDiv(value, 16))

  for i in 0 ..< outputSize: output[i] = staged[i]
  int64(outputSize)
