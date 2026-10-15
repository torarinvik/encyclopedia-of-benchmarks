package length_conversion

meters_per_unit :: proc "contextless" (unit: int) -> f64 {
	switch unit {
	case 0: return 0.001
	case 1: return 0.01
	case 2: return 1.0
	case 3: return 1000.0
	}
	return 0.0
}

@(export)
length_conversion :: proc "c" (value, from_unit_input, to_unit_input: f64) -> f64 {
	if value != value || value < -1_000_000.0 || value > 1_000_000.0 do return -1e300
	if !(from_unit_input == 0.0 || from_unit_input == 1.0 || from_unit_input == 2.0 || from_unit_input == 3.0) do return -1e300
	if !(to_unit_input == 0.0 || to_unit_input == 1.0 || to_unit_input == 2.0 || to_unit_input == 3.0) do return -1e300
	from_unit := int(from_unit_input)
	to_unit := int(to_unit_input)
	return (value * meters_per_unit(from_unit)) / meters_per_unit(to_unit)
}
