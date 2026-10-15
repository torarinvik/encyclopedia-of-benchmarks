module archimedes_principle_of_buoyant_force

// Buoyant force: fluid density * gravity * displaced volume.
@[export: 'archimedes_principle_of_buoyant_force']
pub fn archimedes_principle_of_buoyant_force(values &i64, length usize) f64 {
	if length != 2 { return -1.0e300 }
	fluid_density := unsafe { values[0] }
	volume := unsafe { values[1] }
	if fluid_density < 1 || fluid_density > 1000 || volume < 1 || volume > 1000 {
		return -1.0e300
	}
	return (f64(fluid_density) * 9.80665) * f64(volume)
}
