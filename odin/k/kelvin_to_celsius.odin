package kelvin_to_celsius

@(export)
kelvin_to_celsius :: proc "c" (temperature_in_k: f64) -> f64 {
	if !(temperature_in_k >= 0.0 && temperature_in_k <= 1_000_000.0) do return -1.0
	absolute_zero_in_c := -273.15
	return temperature_in_k + absolute_zero_in_c
}
