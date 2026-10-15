package floor

// Floor for bounded finite binary64 inputs, correcting truncation below zero.
@(export)
floor :: proc "c" (value: f64) -> f64 {
	if value < -1_000_000.0 || value > 1_000_000.0 do return -1.0
	result := i64(value)
	if value < f64(result) do result -= 1
	return f64(result)
}
