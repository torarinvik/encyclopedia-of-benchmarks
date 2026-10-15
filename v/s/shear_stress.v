module shear_stress

@[export: 'shear_stress']
pub fn shear_stress(stress f64, tangential_force f64, area f64) f64 {
	if stress != stress || tangential_force != tangential_force || area != area { return -1.0 }
	if stress < 0.0 || stress > 1000.0 || tangential_force < 0.0 || tangential_force > 1000.0 || area < 0.0 || area > 1000.0 { return -1.0 }
	if stress != f64(i64(stress)) || tangential_force != f64(i64(tangential_force)) || area != f64(i64(area)) { return -1.0 }
	mut zeros := 0
	if stress == 0.0 { zeros++ }
	if tangential_force == 0.0 { zeros++ }
	if area == 0.0 { zeros++ }
	if zeros != 1 { return -1.0 }
	if stress == 0.0 { return tangential_force / area }
	if tangential_force == 0.0 { return stress * area }
	return tangential_force / stress
}
