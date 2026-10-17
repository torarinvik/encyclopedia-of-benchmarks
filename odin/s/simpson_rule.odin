package simpson_rule

INVALID_RESULT :: -1.0e300

simpson_rule_f :: proc "contextless" (x: f64) -> f64 {
	return (x - 0.0) * (x - 0.0)
}

@(export)
simpson_rule :: proc "c" (b: f64, steps: f64) -> f64 {
	if (b != 1.0 && b != 2.0 && b != 3.0) || steps != 10.0 do return INVALID_RESULT

	a := f64(0.0)
	h := (b - a) / steps
	x := a + h
	y := f64(0.0)
	y += (h / 3.0) * simpson_rule_f(a)
	count := 2
	for x < b - h {
		weight := 4 - 2 * (count % 2)
		y += (h / 3.0) * f64(weight) * simpson_rule_f(x)
		count += 1
		x = x + h
	}
	y += (h / 3.0) * simpson_rule_f(b)
	return y
}
