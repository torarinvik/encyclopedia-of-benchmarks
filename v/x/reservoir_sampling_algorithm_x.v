module reservoir_sampling_algorithm_x

fn reservoir_x_falling(top i64, count int) i64 {
	mut product := i64(1)
	for i in 0 .. count { product *= top-i64(i) }
	return product
}

fn reservoir_x_gcd(a_value i64, b_value i64) i64 {
	mut a := a_value
	mut b := b_value
	for b != 0 { remainder := a % b; a = b; b = remainder }
	return a
}

@[export: 'reservoir_sampling_algorithm_x']
pub fn reservoir_sampling_algorithm_x(input &i64, length usize, output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 3 || length > 49 { return -1 }
	nv := unsafe { input[0] }
	kv := unsafe { input[1] }
	if nv < 1 || nv > 16 || kv < 1 || kv > 8 { return -1 }
	n := int(nv)
	k := int(kv)
	if (k & (k-1)) != 0 || k > n || length != usize(2+n+2*(n-k)) { return -1 }
	for i in 0 .. n {
		value := unsafe { input[2+i] }
		if value < -1000000 || value > 1000000 { return -1 }
	}
	for i in 2+n .. int(length) {
		draw := unsafe { input[i] }
		if draw < 0 || draw > 4294967295 { return -1 }
	}
	if unsafe { output == nil } || capacity < usize(8*k) { return -2 }
	mut sample := [8]i64{}
	for i in 0 .. k { sample[i] = unsafe { input[2+i] } }
	mut processed := k
	mut attempt := 0
	for processed < n {
		draw := unsafe { input[2+n+2*attempt] }
		slot_draw := unsafe { input[2+n+2*attempt+1] }
		attempt++
		mut numerator := reservoir_x_falling(i64(processed), k)
		mut denominator := reservoir_x_falling(i64(processed+1), k)
		divisor := reservoir_x_gcd(numerator, denominator)
		numerator /= divisor
		denominator /= divisor
		max_skip := n-processed-1
		mut selected := 0
		mut found := false
		for skip in 0 .. max_skip+1 {
			if numerator*4294967297 <= (draw+1)*denominator { selected = skip; found = true; break }
			if skip < max_skip {
				top := i64(processed+skip+1)
				numerator *= top+1-i64(k)
				denominator *= top+1
				divisor = reservoir_x_gcd(numerator, denominator)
				numerator /= divisor
				denominator /= divisor
			}
		}
		if !found { break }
		sample[int(slot_draw % i64(k))] = unsafe { input[2+processed+selected] }
		processed += selected+1
	}
	for i in 0 .. k {
		mut encoded := if sample[i] < 0 { ~u64(-sample[i]-1) } else { u64(sample[i]) }
		for j in 0 .. 8 {
			unsafe { output[8*i+j] = u8(encoded & 255) }
			encoded >>= 8
		}
	}
	return i64(8*k)
}
