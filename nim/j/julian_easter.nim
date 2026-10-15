## Meeus Julian Easter date encoded as YYYYMMDD.
proc julian_easter*(year: int64): int64 {.cdecl, exportc: "julian_easter".} =
  if year < 1 or year > 9999: return -1
  let a = year mod 4
  let b = year mod 7
  let c = year mod 19
  let d = (19 * c + 15) mod 30
  let e = (2 * a + 4 * b - d + 34) mod 7
  let dayOfYear = d + e + 114
  let month = dayOfYear div 31
  let day = dayOfYear mod 31 + 1
  return year * 10000 + month * 100 + day
