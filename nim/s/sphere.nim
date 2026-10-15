const InvalidResult = -1.0e300
const Pi = 3.14159265358979323846

proc sphere*(input: ptr int64, length: csize_t): float64 {.cdecl, exportc: "sphere".} =
  if input == nil or length != 2: return InvalidResult
  let mode = input[0]
  let radius = input[1]
  if (mode != 0 and mode != 1) or radius < 0 or radius > 1_000_000: return InvalidResult
  let r = float64(radius)
  let r2 = r * r
  if mode == 0: return (((r2 * r) * Pi) * 4.0) / 3.0
  (r2 * Pi) * 4.0
