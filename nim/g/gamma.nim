import std/math

const InvalidResult = -1.0e300

proc gammaRecursiveImpl(num: float64): float64 =
  if num == 0.5: return sqrt(PI)
  if num == 1.0: return 1.0
  (num - 1.0) * gammaRecursiveImpl(num - 1.0)

proc gamma_recursive*(num: float64): float64 {.cdecl, exportc: "gamma_recursive".} =
  if num < 0.5 or num > 20.0 or num * 2.0 != floor(num * 2.0): return InvalidResult
  gammaRecursiveImpl(num)
