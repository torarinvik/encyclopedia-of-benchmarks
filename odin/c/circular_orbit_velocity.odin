package circular_orbit_velocity
import "core:c"
import "core:math"

@(export)
circular_orbit_velocity :: proc "c" (v: [^]f64, n: c.size_t, output: [^]f64, capacity: c.size_t) -> i64 {
	if v == nil || n != c.size_t(2) do return -1
	mass,radius := v[0],v[1]
	if mass != mass || radius != radius || mass < 1.0e-12 || mass > 1.0e25 || radius < 1.0e-12 || radius > 1.0e12 do return -1
	if mass > 1.0e100 || radius > 1.0e100 do return -1
	if output == nil || capacity < c.size_t(1) do return -2
	output[0]=math.sqrt(6.67430e-11*mass/radius)
	return 1
}
