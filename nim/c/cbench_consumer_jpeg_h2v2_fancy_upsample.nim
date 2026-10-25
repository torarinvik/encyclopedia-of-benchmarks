## Independently written bounded IJG h2v2 adaptation; see package README/LICENSE.
const MaxWidth = 16
const MaxHeight = 8
const MaxPixels = 128
const MaxOutput = 512

proc cbench_consumer_jpeg_h2v2_fancy_upsample*(input: ptr UncheckedArray[int64], inputLength: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "cbench_consumer_jpeg_h2v2_fancy_upsample".} =
  if input.isNil or inputLength < 5 or inputLength > 131: return -1
  if input[0] < 3 or input[0] > MaxWidth or input[1] < 1 or input[1] > MaxHeight: return -1
  let width = int(input[0])
  let height = int(input[1])
  let pixels = width * height
  if inputLength != csize_t(2 + pixels): return -1
  for i in 0 ..< pixels:
    if input[i + 2] < 0 or input[i + 2] > 255: return -1
  let outputSize = 4 * pixels
  if output.isNil or outputCapacity < csize_t(outputSize): return -2
  var staged: array[MaxOutput, uint8]
  var p = 0
  for y in 0 ..< height:
    for v in 0 ..< 2:
      let farY = if v == 0: max(0, y - 1) else: min(height - 1, y + 1)
      var sums: array[MaxWidth, int]
      for x in 0 ..< width:
        sums[x] = 3 * int(input[2 + y * width + x]) + int(input[2 + farY * width + x])
      staged[p] = uint8((sums[0] * 4 + 8) shr 4); inc p
      staged[p] = uint8((sums[0] * 3 + sums[1] + 7) shr 4); inc p
      for x in 1 ..< width - 1:
        staged[p] = uint8((sums[x] * 3 + sums[x - 1] + 8) shr 4); inc p
        staged[p] = uint8((sums[x] * 3 + sums[x + 1] + 7) shr 4); inc p
      staged[p] = uint8((sums[width - 1] * 3 + sums[width - 2] + 8) shr 4); inc p
      staged[p] = uint8((sums[width - 1] * 4 + 7) shr 4); inc p
  for i in 0 ..< outputSize: output[i] = staged[i]
  int64(outputSize)
