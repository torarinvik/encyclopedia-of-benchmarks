import std/math

const MaxCashFlows = 8'i64
const MaxRatePpm = 1_000_000'i64
const MaxCashFlowMilli = 1_000_000'i64
const MaxInputLength = 11
const InvalidResult = -1.0e300

proc present_value_rust*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "present_value_rust".} =
  if values == nil or length < 3 or length > csize_t(MaxInputLength): return InvalidResult
  let count = values[0]
  let ratePpm = values[1]
  if count < 1 or count > MaxCashFlows or length != csize_t(count + 2) or
      (ratePpm != 0 and ratePpm != MaxRatePpm): return InvalidResult

  let discountRate = float64(ratePpm) / 1_000_000.0
  var presentValue = 0.0
  for index in 0..<count:
    let cashFlowMilli = values[csize_t(index + 2)]
    if cashFlowMilli < -MaxCashFlowMilli or cashFlowMilli > MaxCashFlowMilli or cashFlowMilli mod 125 != 0:
      return InvalidResult
    let cashFlow = float64(cashFlowMilli) / 1_000.0
    presentValue += cashFlow / pow(1.0 + discountRate, float64(index))
  round(presentValue * 100.0) / 100.0
