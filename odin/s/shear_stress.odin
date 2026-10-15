package shear_stress

@(export)
shear_stress :: proc "c" (stress, tangential_force, area: f64) -> f64 {
	if stress != stress || tangential_force != tangential_force || area != area do return -1.0
	if stress < 0.0 || stress > 1000.0 || tangential_force < 0.0 || tangential_force > 1000.0 || area < 0.0 || area > 1000.0 do return -1.0
	if stress != f64(i64(stress)) || tangential_force != f64(i64(tangential_force)) || area != f64(i64(area)) do return -1.0
	zeros := 0
	if stress == 0.0 do zeros += 1
	if tangential_force == 0.0 do zeros += 1
	if area == 0.0 do zeros += 1
	if zeros != 1 do return -1.0
	if stress == 0.0 do return tangential_force / area
	if tangential_force == 0.0 do return stress * area
	return tangential_force / stress
}
