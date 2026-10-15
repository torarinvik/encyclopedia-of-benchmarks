import std/math

proc fast_inverse_sqrt_java_check*(input: ptr int64, length: csize_t): int64
    {.cdecl, exportc: "fast_inverse_sqrt_java_check".} =
  if input.isNil or length != 2: return -1
  let values = cast[ptr UncheckedArray[int64]](input)
  if values[0] == 0:
    if values[1] < 0x00800000'i64 or values[1] > 0x7f7fffff'i64: return -1
    let bits = uint32(values[1])
    let number = cast[float32](bits)
    let xhalf = 0.5'f32 * number
    let seed = 0x5f3759df'u32 - (bits shr 1)
    var x = cast[float32](seed)
    x = x * (1.5'f32 - xhalf * x * x)
    let expected = 1.0'f32 / float32(sqrt(float64(number)))
    return if x == expected: 1 else: 0
  if values[0] == 1:
    if values[1] < 0x0010000000000000'i64 or values[1] > 0x7fefffffffffffff'i64: return -1
    let bits = uint64(values[1])
    let number = cast[float64](bits)
    let xhalf = 0.5 * number
    let seed = 0x5fe6ec85e7de30da'u64 - (bits shr 1)
    var x = cast[float64](seed)
    for _ in 0 ..< 4: x = x * (1.5 - xhalf * x * x)
    x *= number
    return if x == 1.0 / sqrt(number): 1 else: 0
  -1
