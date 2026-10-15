## Source-ordered Binet formula, rounded to float32 then truncated to int32.
import std/math

proc fibonacci_formula*(input: int64): int64 {.cdecl, exportc: "fibonacci_formula".} =
  if input < 0 or input > 35: return -1
  let n = uint(input)
  let seq = float32((1 / sqrt(5.0) * pow((1 + sqrt(5.0)) / 2, float64(n + 1))) -
                    (1 / sqrt(5.0) * pow((1 - sqrt(5.0)) / 2, float64(n + 1))) )
  int64(int32(seq))
