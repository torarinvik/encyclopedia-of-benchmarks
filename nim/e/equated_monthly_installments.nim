import std/math

const InvalidResult = -1.0e300

proc equated_monthly_installments*(principal, ratePerAnnum, yearsToRepay: float64): float64
    {.cdecl, exportc: "equated_monthly_installments".} =
  if classify(principal) == fcNan or classify(ratePerAnnum) == fcNan or classify(yearsToRepay) == fcNan or
      principal <= 0.0 or principal > 1_000_000.0 or ratePerAnnum < 0.0001 or ratePerAnnum > 0.2 or
      yearsToRepay < 1.0 or yearsToRepay > 30.0 or floor(yearsToRepay) != yearsToRepay:
    return InvalidResult
  let monthlyRate = ratePerAnnum / 12.0
  let payments = yearsToRepay * 12.0
  let factor = pow(1.0 + monthlyRate, payments)
  principal * monthlyRate * factor / (factor - 1.0)
