package celsius_to_fahrenheit

@(export)
celsius_to_fahrenheit :: proc "c" (celsius: f64) -> f64 {
	return (celsius * 9.0 / 5.0) + 32.0
}
