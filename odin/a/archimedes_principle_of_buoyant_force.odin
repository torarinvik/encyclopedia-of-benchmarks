package archimedes_principle_of_buoyant_force

import "core:c"

// Buoyant force: fluid density * gravity * displaced volume.
@(export)
archimedes_principle_of_buoyant_force :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
	if values == nil || length != 2 do return -1.0e300
	fluid_density := values[0]
	volume := values[1]
	if fluid_density < 1 || fluid_density > 1000 || volume < 1 || volume > 1000 do return -1.0e300
	return (f64(fluid_density) * 9.80665) * f64(volume)
}
