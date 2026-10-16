package weight

WEIGHT_FACTORS :: [23]f64{
	1e12, 1e9, 1000.0, 1.0, 1e-3, 1e-6, 1e-9, 1e-12, 1e-15,
	1016.0469088, 907.18474, 50.80234544, 12.70058636,
	6.35029318, 0.45359237, 0.028349523125, 0.0017718451953125, 0.00006479891,
	0.3732417216, 0.0311034768, 0.00155517384, 0.0002, 1.66053906660e-27,
}

weight_factor :: proc "contextless" (code: f64) -> f64 {
	if code != code || code < 0.0 || code > 22.0 do return 0.0
	index := int(code)
	if f64(index) != code do return 0.0
	return WEIGHT_FACTORS[index]
}

// Convert the pinned Rust weight units through kilograms, in source order.
@(export)
weight :: proc "c" (value, from_code, to_code: f64) -> f64 {
	if value != value || value < -1_000_000.0 || value > 1_000_000.0 do return -1e300
	from_factor := weight_factor(from_code)
	to_factor := weight_factor(to_code)
	if from_factor == 0.0 || to_factor == 0.0 do return -1e300
	kilograms := value * from_factor
	return kilograms / to_factor
}
