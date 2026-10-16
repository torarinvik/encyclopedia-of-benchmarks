## Black-Scholes European call/put price. Inputs use thousandths.
import std/math

proc black_scholes_option_price*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "black_scholes_option_price".} =
  if length != 6 or values == nil: return -1.0e300
  let kind = values[0]
  let spot_units = values[1]
  let strike_units = values[2]
  let time_units = values[3]
  let volatility_units = values[4]
  let rate_units = values[5]
  if (kind != 0 and kind != 1) or spot_units < 10 or spot_units > 1000000000 or
      strike_units < 10 or strike_units > 1000000000 or time_units < 1 or time_units > 100000 or
      volatility_units < 1 or volatility_units > 5000 or rate_units < -1000 or rate_units > 1000:
    return -1.0e300
  let spot = float64(spot_units) / 1000.0
  let strike = float64(strike_units) / 1000.0
  let time = float64(time_units) / 1000.0
  let volatility = float64(volatility_units) / 1000.0
  let rate = float64(rate_units) / 1000.0
  let sigma_sqrt_time = volatility * sqrt(time)
  let d1 = (ln(spot / strike) + (rate + volatility * volatility / 2.0) * time) / sigma_sqrt_time
  let d2 = d1 - sigma_sqrt_time
  let cdf_d1 = 0.5 * erfc(-d1 / sqrt(2.0))
  let cdf_d2 = 0.5 * erfc(-d2 / sqrt(2.0))
  if kind == 0: return spot * cdf_d1 - strike * exp(-rate * time) * cdf_d2
  strike * exp(-rate * time) * (0.5 * erfc(d2 / sqrt(2.0))) - spot * (0.5 * erfc(d1 / sqrt(2.0)))
