## Count differing byte positions in two equal-length byte strings.
const MaxByteLength = 1024'i64

proc hamming_distance_bytes*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "hamming_distance_bytes".} =
  if values == nil or length < 1 or length > 2050: return -1
  let countValue = values[0]
  if countValue < 0 or countValue > MaxByteLength or
      length != csize_t(1 + 2 * countValue): return -1
  let count = int(countValue)
  var distance: int64 = 0
  for index in 0 ..< count:
    let left = values[index + 1]
    let right = values[count + index + 1]
    if left < 0 or left > 255 or right < 0 or right > 255: return -1
    if left != right: inc distance
  distance
