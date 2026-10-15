import std/math

const CoefficientLimit = 1_000_000'i64

proc writeF64Le(output: ptr UncheckedArray[uint8], offset: int, value: float64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 0xFF'u64)

proc quadratic_roots*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "quadratic_roots".} =
  if values == nil or length != 3: return -1
  let ai = values[0]
  let bi = values[1]
  let ci = values[2]
  if ai == 0 or ai < -CoefficientLimit or ai > CoefficientLimit or
      bi < -CoefficientLimit or bi > CoefficientLimit or
      ci < -CoefficientLimit or ci > CoefficientLimit: return -1

  let a = float64(ai)
  let b = float64(bi)
  let c = float64(ci)
  let discriminant = b * b - 4.0 * a * c
  if discriminant < 0.0: return 0

  if discriminant == 0.0:
    if output == nil or outputCapacity < 8: return -2
    writeF64Le(output, 0, -b / (2.0 * a))
    return 1

  if output == nil or outputCapacity < 16: return -2
  let squareRoot = sqrt(discriminant)
  writeF64Le(output, 0, (-b + squareRoot) / (2.0 * a))
  writeF64Le(output, 8, (-b - squareRoot) / (2.0 * a))
  2

