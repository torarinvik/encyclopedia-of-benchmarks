package coulombs_law

import "core:c"

Coulombs_Constant :: 8.9875517923e9
Max_Charge_Microcoulombs :: 1_000_000
Max_Distance_Millimeters :: 1_000_000

@(export)
coulombs_law :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
	if values == nil || length != 3 do return -1.0e300
	charge1_value, charge2_value, distance_value := values[0], values[1], values[2]
	if charge1_value == 0 || charge2_value == 0 ||
		charge1_value < -Max_Charge_Microcoulombs || charge1_value > Max_Charge_Microcoulombs ||
		charge2_value < -Max_Charge_Microcoulombs || charge2_value > Max_Charge_Microcoulombs ||
		distance_value < 1 || distance_value > Max_Distance_Millimeters do return -1.0e300

	charge1 := f64(charge1_value) / 1_000_000.0
	charge2 := f64(charge2_value) / 1_000_000.0
	distance := f64(distance_value) / 1_000.0
	charge_product := charge1 * charge2
	if charge_product < 0.0 do charge_product = -charge_product
	return Coulombs_Constant * charge_product / (distance * distance)
}
