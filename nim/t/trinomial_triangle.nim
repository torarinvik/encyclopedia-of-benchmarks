proc trinomialValue(n, k: int64): int64 =
  if n == 0 and k == 0: return 1
  if k < -n or k > n: return 0
  trinomialValue(n - 1, k - 1) +
    trinomialValue(n - 1, k) +
    trinomialValue(n - 1, k + 1)

proc trinomial_triangle*(n, k: int64): int64
    {.cdecl, exportc: "trinomial_triangle".} =
  if n < 0 or n > 10 or k < -10 or k > 10: return -1
  trinomialValue(n, k)
