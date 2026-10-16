const Scale = 1_000_000'i64
const MaxPriceMicro = 1_000_000_000_000'i64
const MaxTaxRateMicro = 1_000_000'i64
const MaxInputLength = 3
const InvalidResult = -1.0e300

proc price_plus_tax*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "price_plus_tax".} =
  if values == nil or length != 2 or length > csize_t(MaxInputLength): return InvalidResult
  let priceMicro = values[0]
  let taxRateMicro = values[1]
  if priceMicro < 0 or priceMicro > MaxPriceMicro or taxRateMicro < 0 or taxRateMicro > MaxTaxRateMicro: return InvalidResult
  let price = float64(priceMicro) / float64(Scale)
  let taxRate = float64(taxRateMicro) / float64(Scale)
  price * (1.0 + taxRate)
