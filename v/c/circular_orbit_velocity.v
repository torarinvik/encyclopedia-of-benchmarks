module circular_orbit_velocity
import math

@[export: 'circular_orbit_velocity']
pub fn circular_orbit_velocity(values &f64, length usize, mut output &f64, capacity usize) i64 {
	unsafe {
		if isnil(values) || length != 2 { return -1 }
		mass,radius := values[0],values[1]
		if mass != mass || radius != radius || mass < 1.0e-12 || mass > 1.0e25 || radius < 1.0e-12 || radius > 1.0e12 { return -1 }
		if isnil(output) || capacity < 1 { return -2 }
		output[0]=math.sqrt(6.67430e-11*mass/radius)
		return 1
	}
}
