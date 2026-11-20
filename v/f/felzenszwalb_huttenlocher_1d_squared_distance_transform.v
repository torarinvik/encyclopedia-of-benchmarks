module felzenszwalb_huttenlocher_1d_squared_distance_transform

const max_sites = 128
const max_input_words = 130
const sentinel = i64(-4611686018427387904)

fn floor_div(numerator i64, denominator i64) i64 {
	mut quotient := numerator / denominator
	if numerator % denominator != 0 && numerator < 0 {
		quotient -= 1
	}
	return quotient
}

fn store_i64_le(mut output &u8, word int, value i64) {
	mut bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[word * 8 + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'felzenszwalb_huttenlocher_1d_squared_distance_transform']
pub fn felzenszwalb_huttenlocher_1d_squared_distance_transform(input &i64,
	length usize, mut output &u8, output_capacity usize) i64 {
	if unsafe { input == nil } || length < 2 || length > max_input_words { return -1 }
	n64 := unsafe { input[0] }
	if n64 < 1 || n64 > max_sites { return -1 }
	n := int(n64)
	if int(length) != n + 1 { return -1 }
	for i in 0 .. n {
		cost := unsafe { input[i + 1] }
		if cost < 0 || cost > 1000000 { return -1 }
	}
	if output == nil || output_capacity < usize(n * 16) { return -2 }

	mut sites := [max_sites]usize{}
	mut starts := [max_sites]i64{}
	mut top := 0
	sites[0] = 0
	starts[0] = sentinel
	for q in 1 .. n {
		for {
			p := int(sites[top])
			numerator := unsafe { input[q + 1] } + i64(q * q)
				- unsafe { input[p + 1] } - i64(p * p)
			denominator := i64(2 * (q - p))
			first := floor_div(numerator, denominator) + 1
			if top == 0 || first > starts[top] {
				top++
				sites[top] = usize(q)
				starts[top] = first
				break
			}
			top--
		}
	}

	mut active := 0
	for x in 0 .. n {
		for active < top && starts[active + 1] <= i64(x) { active++ }
		site := int(sites[active])
		delta := i64(x - site)
		distance := delta * delta + unsafe { input[site + 1] }
		store_i64_le(mut output, 2 * x, distance)
		store_i64_le(mut output, 2 * x + 1, i64(site))
	}
	return i64(n * 16)
}
