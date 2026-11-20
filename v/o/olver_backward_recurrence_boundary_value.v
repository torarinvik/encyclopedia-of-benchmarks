const olver_max_parseable_input_length = 53
const olver_max_nmax = 12

fn olver_exact_integer(value f64, low int, high int) ?int {
	if !value.is_finite() || value < f64(low) || value > f64(high) || f64(int(value)) != value { return none }
	return int(value)
}

@[export: 'olver_backward_recurrence_boundary_value']
pub fn olver_backward_recurrence_boundary_value(input &f64, input_length usize,
	mut output &f64, output_capacity usize) i64 {
	unsafe {
		if input == nil || input_length < 8 || input_length > olver_max_parseable_input_length { return -1 }
		for i in 0 .. input_length { if !input[i].is_finite() { return -1 } }
		m_value := olver_exact_integer(input[0], 1, 8) or { return -1 }
		nmax := olver_exact_integer(input[1], 1, olver_max_nmax) or { return -1 }
		if m_value > nmax || input_length != usize(4 + 4 * nmax) || input[2] < 9.094947017729282e-13 ||
			input[2] > 0.5 || math.abs(input[3]) > 16.0 { return -1 }
		for i in 0 .. nmax {
			if math.abs(input[4+i]) < 0.0625 || math.abs(input[4+i]) > 16.0 ||
				math.abs(input[4+nmax+i]) > 16.0 || math.abs(input[4+2*nmax+i]) > 16.0 ||
				math.abs(input[4+3*nmax+i]) > 16.0 { return -1 }
		}
		required := m_value + 2
		if output == nil || output_capacity < usize(required) { return -2 }
		m := m_value
		mut p := [14]f64{}
		mut e := [13]f64{}
		mut w := [13]f64{}
		p[1] = 1.0
		e[0] = input[3]
		for n in 1 .. m_value + 1 {
			a := input[4+n-1]
			b := input[4+nmax+n-1]
			c := input[4+2*nmax+n-1]
			d := input[4+3*nmax+n-1]
			p[n+1] = (b*p[n]-c*p[n-1])/a
			e[n] = (c*e[n-1]-d*p[n])/a
			if !p[n+1].is_finite() || !e[n].is_finite() { return -3 }
		}
		for n in 1 .. m_value + 1 {
			product := p[n]*p[n+1]
			if product == 0.0 || !product.is_finite() || !(e[n]/product).is_finite() { return -3 }
		}
		mut minimum := math.abs(e[1]/(p[1]*p[2]))
		for n in 2 .. m + 1 {
			ratio := math.abs(e[n]/(p[n]*p[n+1]))
			if ratio < minimum { minimum = ratio }
		}
		threshold := input[2]*minimum
		mut endpoint := 0
		for n in m .. nmax + 1 {
			if n > m {
				a := input[4+n-1]
				b := input[4+nmax+n-1]
				c := input[4+2*nmax+n-1]
				d := input[4+3*nmax+n-1]
				p[n+1] = (b*p[n]-c*p[n-1])/a
				e[n] = (c*e[n-1]-d*p[n])/a
				if !p[n+1].is_finite() || !e[n].is_finite() { return -3 }
			}
			product := p[n]*p[n+1]
			if product == 0.0 || !product.is_finite() { return -3 }
			ratio := math.abs(e[n]/product)
			if !ratio.is_finite() { return -3 }
			if ratio <= threshold { endpoint = n; break }
		}
		if endpoint == 0 { return -3 }
		for n := endpoint-1; n >= 0; n-- {
			w[n] = (p[n]*w[n+1]+e[n])/p[n+1]
			if !w[n].is_finite() { return -3 }
		}
		output[0] = f64(endpoint)
		for i in 0 .. m + 1 { output[i+1] = w[i] }
		return i64(required)
	}
}
