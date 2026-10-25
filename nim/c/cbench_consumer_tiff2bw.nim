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

const MaxPixels = 64
const MaxInputLength = 193

proc cbench_consumer_tiff2bw*(input: ptr UncheckedArray[int64], inputLength: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "cbench_consumer_tiff2bw".} =
  if input.isNil or inputLength < 4 or inputLength > MaxInputLength: return -1
  if input[0] < 1 or input[0] > MaxPixels: return -1
  let pixelCount = int(input[0])
  if inputLength != csize_t(1 + 3 * pixelCount): return -1
  for i in 1 ..< int(inputLength):
    if input[i] < 0 or input[i] > 255: return -1
  if output.isNil or outputCapacity < csize_t(pixelCount): return -2

  for pixel in 0 ..< pixelCount:
    let at = 1 + 3 * pixel
    var value = 71 * int(input[at])
    value += 150 * int(input[at + 1])
    value += 28 * int(input[at + 2])
    output[pixel] = uint8(value shr 8)
  int64(pixelCount)
