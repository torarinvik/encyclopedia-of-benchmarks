import std/math

const SideLimit = 1_000_000.0

proc herons_formula*(a, b, c: float64): float64
    {.cdecl, exportc: "herons_formula".} =
  if a < 1.0 or a > SideLimit or floor(a) != a or
      b < 1.0 or b > SideLimit or floor(b) != b or
      c < 1.0 or c > SideLimit or floor(c) != c or
      a + b <= c or b + c <= a or c + a <= b: return -1.0
  let s = (a + b + c) / 2.0
  sqrt((s) * (s - a) * (s - b) * (s - c))

