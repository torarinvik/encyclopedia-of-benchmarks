package gross_profit_margin

import "core:c"

INVALID_RESULT :: -1.0e300

@(export)
gross_profit_margin :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
	if values == nil || length != c.size_t(2) do return INVALID_RESULT
	revenue := values[0]
	cost := values[1]
	if revenue < 1 || revenue > 1000000 || cost < 0 || cost > 1000000 do return INVALID_RESULT
	return (f64(revenue) - f64(cost)) / f64(revenue)
}
