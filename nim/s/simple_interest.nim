proc simple_interest*(principal, dailyRate, days: float64): float64 {.cdecl, exportc: "simple_interest".} =
  if principal != principal or dailyRate != dailyRate or days != days or
      not (principal > 0.0) or principal > 1_000_000.0 or
      not (dailyRate >= 0.0) or dailyRate > 1.0 or
      not (days > 0.0) or days > 3_650.0: return -1e300
  principal * dailyRate * days
