module coulombs_law

const coulombs_constant = 8.9875517923e9
const max_charge_microcoulombs = 1_000_000
const max_distance_millimeters = 1_000_000

@[export: 'coulombs_law']
pub fn coulombs_law(values &i64, length usize) f64 {
	if unsafe { values == nil } || length != 3 { return -1.0e300 }
	unsafe {
		charge1_value, charge2_value, distance_value := values[0], values[1], values[2]
		if charge1_value == 0 || charge2_value == 0 ||
			charge1_value < -max_charge_microcoulombs || charge1_value > max_charge_microcoulombs ||
			charge2_value < -max_charge_microcoulombs || charge2_value > max_charge_microcoulombs ||
			distance_value < 1 || distance_value > max_distance_millimeters { return -1.0e300 }
		charge1 := f64(charge1_value) / 1_000_000.0
		charge2 := f64(charge2_value) / 1_000_000.0
		distance := f64(distance_value) / 1_000.0
		mut charge_product := charge1 * charge2
		if charge_product < 0.0 { charge_product = -charge_product }
		return coulombs_constant * charge_product / (distance * distance)
	}
}
