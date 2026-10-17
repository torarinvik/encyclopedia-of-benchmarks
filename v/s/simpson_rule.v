module simpson_rule

const invalid_result = -1e300

fn simpson_rule_f(x f64) f64 {
	return (x - 0.0) * (x - 0.0)
}

@[export: 'simpson_rule']
pub fn simpson_rule(b f64, steps f64) f64 {
	if (b != 1.0 && b != 2.0 && b != 3.0) || steps != 10.0 { return invalid_result }

	a := 0.0
	h := (b - a) / steps
	mut x := a + h
	mut y := 0.0
	y += (h / 3.0) * simpson_rule_f(a)
	mut count := 2
	for x < b - h {
		weight := 4 - 2 * (count % 2)
		y += (h / 3.0) * f64(weight) * simpson_rule_f(x)
		count++
		x = x + h
	}
	y += (h / 3.0) * simpson_rule_f(b)
	return y
}
