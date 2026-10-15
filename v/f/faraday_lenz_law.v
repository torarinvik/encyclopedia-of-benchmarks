module faraday_lenz_law

@[export: 'faraday_lenz_law']
pub fn faraday_lenz_law(values &i64, length usize) i64 {
	if unsafe { values == nil } || length != 3 { return i64(-9223372036854775807) - 1 }
	unsafe {
		final_flux, initial_flux, interval := values[0], values[1], values[2]
		if final_flux < -1000000000 || final_flux > 1000000000 || initial_flux < -1000000000
			|| initial_flux > 1000000000 || interval < 1 || interval > 1000000000 {
			return i64(-9223372036854775807) - 1
		}
		numerator := -(final_flux - initial_flux) * 10
		magnitude := numerator
		if magnitude < 0 { magnitude = -magnitude }
		mut quotient := magnitude / interval
		remainder := magnitude % interval
		if 2 * remainder > interval || (2 * remainder == interval && quotient % 2 != 0) { quotient++ }
		if numerator < 0 { return -quotient }
		return quotient
	}
}
