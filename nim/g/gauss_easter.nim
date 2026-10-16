proc gaussEaster*(year: int64): int64 {.cdecl, exportc: "gauss_easter".} =
  if year < 1 or year > 9999: return -1
  let a = year mod 19
  let b = year mod 4
  let c = year mod 7
  let century = year div 100
  let lunarCorrection = (13 + 8 * century) div 25
  let moonQ = (60 - 4 * lunarCorrection + 3 * century) mod 120
  let startQ = (16 + 3 * century) mod 28
  let addQ = (76 * a + moonQ) mod 120
  let sundayQ = (8 * b + 16 * c + startQ + 6 * addQ) mod 28
  var month, day: int64
  if addQ == 116 and sundayQ == 24:
    month = 4
    day = 19
  elif addQ == 112 and sundayQ == 24:
    month = 4
    day = 18
  else:
    let marchDay = 22 + (addQ + sundayQ) div 4
    if marchDay <= 31:
      month = 3
      day = marchDay
    else:
      month = 4
      day = marchDay - 31
  year * 10000 + month * 100 + day
