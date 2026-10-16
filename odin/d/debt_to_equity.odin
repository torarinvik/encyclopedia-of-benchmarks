package debt_to_equity

import "core:c"

INVALID_RESULT :: -1.0e300

@(export)
debt_to_equity :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
	if values == nil || length != c.size_t(2) do return INVALID_RESULT
	debt := values[0]
	equity := values[1]
	if debt < 0 || debt > 1000000 || equity < 1 || equity > 1000000 do return INVALID_RESULT
	return f64(debt) / f64(equity)
}
