module freebench_pifft

const fft_size = 8
const base = i64(1000)
const scale = i64(1000000)

fn fft_transform(mut real &f64, mut imag &f64, inverse bool) {
	unsafe {
		mut j := 0
		for i in 1 .. fft_size {
			mut bit := fft_size >> 1
			for (j & bit) != 0 { j ^= bit; bit >>= 1 }
			j ^= bit
			if i < j {
				t := real[i]; real[i] = real[j]; real[j] = t
				t = imag[i]; imag[i] = imag[j]; imag[j] = t
			}
		}
		mut length := 2
		for length <= fft_size {
			mut root_real := 0.0
			mut root_imag := 0.0
			if length == 2 { root_real = -1.0 }
			else if length == 4 { root_imag = if inverse { 1.0 } else { -1.0 } }
			else { root_real = 0.7071067811865476; root_imag = if inverse { 0.7071067811865476 } else { -0.7071067811865476 } }
			half := length >> 1
			for start := 0; start < fft_size; start += length {
				mut wr := 1.0
				mut wi := 0.0
				for offset in 0 .. half {
					even := start + offset
					odd := even + half
					vr := real[odd]*wr - imag[odd]*wi
					vi := real[odd]*wi + imag[odd]*wr
					ur, ui := real[even], imag[even]
					real[even], imag[even] = ur+vr, ui+vi
					real[odd], imag[odd] = ur-vr, ui-vi
					next_wr := wr*root_real - wi*root_imag
					wi = wr*root_imag + wi*root_real
					wr = next_wr
				}
			}
			length <<= 1
		}
		if inverse { for i in 0 .. fft_size { real[i] /= f64(fft_size); imag[i] /= f64(fft_size) } }
	}
}

fn fft_multiply_fixed(left_value i64, right_value i64) i64 {
	mut left := left_value
	mut right := right_value
	mut sign := i64(1)
	if left < 0 { sign = -sign; left = -left }
	if right < 0 { sign = -sign; right = -right }
	mut left_real := [fft_size]f64{}
	mut left_imag := [fft_size]f64{}
	mut right_real := [fft_size]f64{}
	mut right_imag := [fft_size]f64{}
	for i in 0 .. 3 {
		left_real[i] = f64(left % base)
		right_real[i] = f64(right % base)
		left /= base
		right /= base
	}
	fft_transform(mut &left_real[0], mut &left_imag[0], false)
	fft_transform(mut &right_real[0], mut &right_imag[0], false)
	for i in 0 .. fft_size {
		pr := left_real[i]*right_real[i] - left_imag[i]*right_imag[i]
		pi := left_real[i]*right_imag[i] + left_imag[i]*right_real[i]
		left_real[i], left_imag[i] = pr, pi
	}
	fft_transform(mut &left_real[0], mut &left_imag[0], true)
	mut product := i64(0)
	mut place := i64(1)
	for i in 0 .. 5 {
		coefficient := i64(left_real[i] + 0.5)
		product += coefficient * place
		place *= base
	}
	return sign * ((product + scale/2) / scale)
}

fn fixed_sqrt(value i64) i64 {
	if value <= 0 { return 0 }
	radicand := value * scale
	mut root := radicand
	for {
		next := (root + radicand/root) / 2
		if next >= root { break }
		root = next
	}
	lower_error := radicand - root*root
	upper_error := (root+1)*(root+1) - radicand
	if upper_error < lower_error { return root+1 }
	return root
}

fn fixed_half(value i64) i64 {
	if value < 0 { return -((-value)/2) }
	return value/2
}

fn fixed_divide(numerator i64, denominator i64) i64 {
	if denominator <= 0 { return 0 }
	scaled := numerator * scale
	if scaled < 0 { return -((-scaled+denominator/2)/denominator) }
	return (scaled+denominator/2)/denominator
}

@[export: 'freebench_pifft']
pub fn freebench_pifft(nfft i64) i64 {
	if nfft != i64(fft_size) { return -1 }
	mut c := fixed_sqrt(125000)
	mut a := scale + 3*c
	mut b := fixed_sqrt(a)
	mut e := b - 625000
	b *= 2
	c = e - c
	a += e
	mut npow := i64(4)
	for _ in 0 .. 8 {
		npow *= 2
		e = fixed_half(a+b)
		b = fixed_sqrt(fft_multiply_fixed(a, b))
		e -= b
		b *= 2
		c -= e
		a = e+b
		if e >= -1 && e <= 1 { break }
	}
	e = fixed_half(e)
	e = fft_multiply_fixed(e, e)
	a += b
	numerator := fft_multiply_fixed(a, a) - e - fixed_half(e)
	denominator := fft_multiply_fixed(a, c) - e
	mut pi := fixed_divide(numerator, denominator)
	pi = (pi + npow/2) / npow
	return (pi+500)/1000
}
