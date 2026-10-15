## Gregorian Easter date, packed as month * 100 + day.
proc easter*(year: int64): int64 {.cdecl, exportc: "easter".} =
  if year < 0 or year > 9999:
    return -1
  if year <= 1582:
    return 0
  let a = year mod 19
  let b = year div 100
  let c = year mod 100
  let d = b div 4
  let e = b mod 4
  let f = (b + 8) div 25
  let g = (b - f + 1) div 3
  let h = (19 * a + b - d - g + 15) mod 30
  let i = c div 4
  let k = c mod 4
  let r = (32 + 2 * e + 2 * i - h - k) mod 7
  let m = (a + 11 * h + 22 * r) div 451
  let date = h + r - 7 * m + 114
  let month = date div 31
  let day = date mod 31 + 1
  month * 100 + day
