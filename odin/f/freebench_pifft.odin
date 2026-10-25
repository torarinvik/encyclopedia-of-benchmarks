package freebench_pifft

FFT_SIZE :: 8
BASE :: 1000
SCALE :: 1_000_000

fft_transform :: proc "contextless" (real, imag: [^]f64, inverse: bool) {
	j := 0
	for i := 1; i < FFT_SIZE; i += 1 {
		bit := FFT_SIZE >> 1
		for (j & bit) != 0 { j ^= bit; bit >>= 1 }
		j ^= bit
		if i < j {
			t := real[i]; real[i] = real[j]; real[j] = t
			t = imag[i]; imag[i] = imag[j]; imag[j] = t
		}
	}
	for length := 2; length <= FFT_SIZE; length <<= 1 {
		root_real, root_imag: f64
		if length == 2 { root_real, root_imag = -1.0, 0.0 }
		else if length == 4 { root_real, root_imag = 0.0, 1.0; if !inverse { root_imag = -1.0 } }
		else { root_real = 0.7071067811865476; root_imag = 0.7071067811865476; if !inverse { root_imag = -root_imag } }
		half := length >> 1
		for start := 0; start < FFT_SIZE; start += length {
			wr, wi: f64 = 1.0, 0.0
			for offset := 0; offset < half; offset += 1 {
				even, odd := start+offset, start+offset+half
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
	}
	if inverse { for i := 0; i < FFT_SIZE; i += 1 { real[i] /= f64(FFT_SIZE); imag[i] /= f64(FFT_SIZE) } }
}

fft_multiply_fixed :: proc "contextless" (left_value, right_value: i64) -> i64 {
	left, right := left_value, right_value
	sign: i64 = 1
	if left < 0 { sign = -sign; left = -left }
	if right < 0 { sign = -sign; right = -right }
	left_real, left_imag := [8]f64{}, [8]f64{}
	right_real, right_imag := [8]f64{}, [8]f64{}
	for i := 0; i < 3; i += 1 {
		left_real[i] = f64(left % BASE)
		right_real[i] = f64(right % BASE)
		left /= BASE
		right /= BASE
	}
	fft_transform(&left_real[0], &left_imag[0], false)
	fft_transform(&right_real[0], &right_imag[0], false)
	for i := 0; i < FFT_SIZE; i += 1 {
		pr := left_real[i]*right_real[i] - left_imag[i]*right_imag[i]
		pi := left_real[i]*right_imag[i] + left_imag[i]*right_real[i]
		left_real[i], left_imag[i] = pr, pi
	}
	fft_transform(&left_real[0], &left_imag[0], true)
	product, place: i64 = 0, 1
	for i := 0; i < 5; i += 1 {
		coefficient := i64(left_real[i] + 0.5)
		product += coefficient * place
		place *= BASE
	}
	return sign * ((product + SCALE/2) / SCALE)
}

fixed_sqrt :: proc "contextless" (value: i64) -> i64 {
	if value <= 0 do return 0
	radicand := value * SCALE
	root := radicand
	for {
		next := (root + radicand/root) / 2
		if next >= root do break
		root = next
	}
	lower_error := radicand - root*root
	upper_error := (root+1)*(root+1) - radicand
	if upper_error < lower_error do return root+1
	return root
}

fixed_half :: proc "contextless" (value: i64) -> i64 {
	if value < 0 do return -((-value)/2)
	return value/2
}

fixed_divide :: proc "contextless" (numerator, denominator: i64) -> i64 {
	if denominator <= 0 do return 0
	scaled := numerator * SCALE
	if scaled < 0 do return -((-scaled+denominator/2)/denominator)
	return (scaled+denominator/2)/denominator
}

@(export)
freebench_pifft :: proc "c" (nfft: i64) -> i64 {
	if nfft != FFT_SIZE do return -1
	c := fixed_sqrt(125_000)
	a := SCALE + 3*c
	b := fixed_sqrt(a)
	e := b - 625_000
	b *= 2
	c = e - c
	a += e
	npow: i64 = 4
	for iteration := 0; iteration < 8; iteration += 1 {
		npow *= 2
		e = fixed_half(a+b)
		b = fixed_sqrt(fft_multiply_fixed(a, b))
		e -= b
		b *= 2
		c -= e
		a = e+b
		if e >= -1 && e <= 1 do break
	}
	e = fixed_half(e)
	e = fft_multiply_fixed(e, e)
	a += b
	numerator := fft_multiply_fixed(a, a) - e - fixed_half(e)
	denominator := fft_multiply_fixed(a, c) - e
	pi := fixed_divide(numerator, denominator)
	pi = (pi+npow/2)/npow
	return (pi+500)/1000
}
