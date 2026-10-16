package earnings_per_sale

import "core:c"

INVALID_RESULT :: -1.0e300

@(export)
earnings_per_sale :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
	if values == nil || length != c.size_t(3) do return INVALID_RESULT
	net_income := values[0]
	preferred_dividend := values[1]
	average_shares := values[2]
	if net_income < -1000000 || net_income > 1000000 || preferred_dividend < 0 || preferred_dividend > 1000000 || average_shares < 1 || average_shares > 1000000 do return INVALID_RESULT
	return (f64(net_income) - f64(preferred_dividend)) / f64(average_shares)
}
