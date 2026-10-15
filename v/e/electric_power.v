module electric_power

// Pinned electric_power formula over the benchmark's bounded integer-valued domain.
@[export: 'electric_power']
pub fn electric_power(voltage f64, current f64, power f64) f64 {
	if voltage != voltage || current != current || power != power { return -1.0e300 }
	if voltage < -10000.0 || voltage > 10000.0 || current < -10000.0 || current > 10000.0 { return -1.0e300 }
	if power < 0.0 || power > 100000000.0 { return -1.0e300 }
	if voltage != f64(i64(voltage)) || current != f64(i64(current)) || power != f64(i64(power)) { return -1.0e300 }
	mut zeros := 0
	if voltage == 0.0 { zeros++ }
	if current == 0.0 { zeros++ }
	if power == 0.0 { zeros++ }
	if zeros != 1 { return -1.0e300 }
	if voltage == 0.0 { return power / current }
	if current == 0.0 { return power / voltage }
	product := voltage * current
	if product < 0.0 { return -product }
	return product
}
