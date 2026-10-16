proc problem17*(limit: int64): int64 {.cdecl, exportc: "problem17".} =
  if limit < 0 or limit > 1000: return -1
  const ones = [0'i64, 3, 3, 5, 4, 4, 3, 5, 5, 4, 3, 6, 6, 8, 8, 7, 7, 9, 8, 8]
  const tens = [0'i64, 0, 6, 6, 5, 5, 5, 7, 6, 6]
  var total = 0'i64
  for value in 1'i64..limit:
    if value == 1000:
      total += ones[1] + 8
    else:
      var remainder = value
      if value >= 100:
        total += ones[int(value div 100)] + 7
        remainder = value mod 100
        if remainder != 0: total += 3
      if remainder < 20:
        total += ones[int(remainder)]
      else:
        total += tens[int(remainder div 10)] + ones[int(remainder mod 10)]
  total
