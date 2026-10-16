package return_on_investment

import "core:c"

INVALID_RESULT :: -1.0e300

@(export)
return_on_investment :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
	if values == nil || length != c.size_t(2) do return INVALID_RESULT
	gain := values[0]
	cost := values[1]
	if gain < -1000000 || gain > 1000000 || cost < 1 || cost > 1000000 do return INVALID_RESULT
	return (f64(gain) - f64(cost)) / f64(cost)
}
