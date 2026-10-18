const MaxParseableInputLength = 196
const MaxOutputBytes = 192

proc sepia*(input: ptr UncheckedArray[int64], inputLength: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "sepia".} =
  if input == nil or inputLength < 3 or inputLength > MaxParseableInputLength.csize_t: return -1
  let height = input[0]
  let width = input[1]
  let factor = input[2]
  if height < 1 or height > 8 or width < 1 or width > 8 or factor < 0 or factor > 255: return -1
  let pixels = int(height * width)
  if inputLength != csize_t(3 + 3 * pixels): return -1
  for index in 0 ..< 3 * pixels:
    let channel = input[3 + index]
    if channel != 0 and channel != 64 and channel != 128 and channel != 255: return -1

  var staged: array[MaxOutputBytes, uint8]
  for pixel in 0 ..< pixels:
    let offset = 3 + 3 * pixel
    let blue = float64(input[offset])
    let green = float64(input[offset + 1])
    let red = float64(input[offset + 2])
    let gray = int64(0.2126 * red + 0.587 * green + 0.114 * blue)
    staged[3 * pixel] = uint8(gray)
    let tintedGreen = min(gray + factor, 255'i64)
    let tintedRed = min(gray + 2 * factor, 255'i64)
    staged[3 * pixel + 1] = uint8(tintedGreen)
    staged[3 * pixel + 2] = uint8(tintedRed)

  let outputBytes = 3 * pixels
  if output == nil or capacity < csize_t(outputBytes): return -2
  for index in 0 ..< outputBytes: output[index] = staged[index]
  int64(outputBytes)
