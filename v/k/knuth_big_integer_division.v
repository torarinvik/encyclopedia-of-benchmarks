module knuth_big_integer_division

const base = i64(1_000_000_000)
const max_limbs = 8
const max_input = 130
const max_output = 129

fn trim(x [max_limbs]i64, count_input int) int {
	mut count := count_input
	for count > 0 && x[count - 1] == 0 { count-- }
	return count
}

fn parse_limbs(text &i64, length int) [max_limbs]i64 {
	mut limbs := [max_limbs]i64{}
	mut count := 0
	for at in 0 .. length {
		mut carry := unsafe { text[at] - 48 }
		for i in 0 .. count {
			carry += limbs[i] * 10
			limbs[i] = carry % base
			carry /= base
		}
		if carry != 0 { limbs[count] = carry; count++ }
		if count == 0 { count = 1 }
	}
	return limbs
}

fn compare(a [max_limbs]i64, na int, b [max_limbs]i64, nb int) int {
	if na != nb { return if na > nb { 1 } else { -1 } }
	for i := na - 1; i >= 0; i-- {
		if a[i] != b[i] { return if a[i] > b[i] { 1 } else { -1 } }
	}
	return 0
}

fn divide_limbs(a [max_limbs]i64, na int, b [max_limbs]i64, nb int,
	mut q [max_limbs]i64, mut r [max_limbs]i64) (int, int) {
	if na == 0 { return 0, 0 }
	if compare(a, na, b, nb) < 0 { r = a; return 0, na }
	if nb == 1 {
		mut rem := i64(0)
		for i := na - 1; i >= 0; i-- {
			cur := rem * base + a[i]
			q[i] = cur / b[0]
			rem = cur % b[0]
		}
		if rem != 0 { r[0] = rem; return trim(q, na), 1 }
		return trim(q, na), 0
	}
	mut v := [max_limbs]i64{}
	mut u := [max_limbs + 1]i64{}
	scale := base / (b[nb - 1] + 1)
	mut carry := i64(0)
	for i in 0 .. nb { cur := b[i] * scale + carry; v[i] = cur % base; carry = cur / base }
	carry = 0
	for i in 0 .. na { cur := a[i] * scale + carry; u[i] = cur % base; carry = cur / base }
	u[na] = carry
	width := na - nb + 1
	for step := width - 1; step >= 0; step-- {
		numerator := u[step + nb] * base + u[step + nb - 1]
		mut estimate := numerator / v[nb - 1]
		mut rem_estimate := numerator % v[nb - 1]
		if estimate >= base { estimate = base - 1; rem_estimate = numerator - estimate * v[nb - 1] }
		for rem_estimate < base && estimate * v[nb - 2] > rem_estimate * base + u[step + nb - 2] {
			estimate--
			rem_estimate += v[nb - 1]
		}
		mut borrow := i64(0)
		for i in 0 .. nb {
			product := estimate * v[i] + borrow
			low := product % base
			borrow = product / base
			mut difference := u[step + i] - low
			if difference < 0 { difference += base; borrow++ }
			u[step + i] = difference
		}
		top := u[step + nb] - borrow
		if top < 0 {
			estimate--
			carry = 0
			for i in 0 .. nb {
				mut sum := u[step + i] + v[i] + carry
				if sum >= base { sum -= base; carry = 1 } else { carry = 0 }
				u[step + i] = sum
			}
		u[step + nb] = top + carry
		} else { u[step + nb] = top }
		q[step] = estimate
	}
	carry = 0
	for i := nb - 1; i >= 0; i-- { cur := carry * base + u[i]; r[i] = cur / scale; carry = cur % scale }
	return trim(q, width), trim(r, nb)
}

fn emit(x [max_limbs]i64, count_input int, mut output [max_output]u8, at_input int) int {
	mut count := trim(x, count_input)
	mut at := at_input
	if count == 0 { output[at] = u8(48); return at + 1 }
	mut value := x[count - 1]
	mut power := i64(1)
	for value / power >= 10 { power *= 10 }
	for power > 0 { output[at] = u8(48 + value / power % 10); at++; power /= 10 }
	for count > 1 {
		count--
		value = x[count - 1]
		power = base / 10
		for power > 0 { output[at] = u8(48 + value / power % 10); at++; power /= 10 }
	}
	return at
}

@[export: 'knuth_big_integer_division']
pub fn knuth_big_integer_division(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 4 || length > max_input { return -1 }
		if input[0] < 1 || input[0] > 64 || input[1] < 1 || input[1] > 64 { return -1 }
		na_text := int(input[0]); nb_text := int(input[1])
		if int(length) != 2 + na_text + nb_text { return -1 }
		for i in 0 .. na_text { if input[2 + i] < 48 || input[2 + i] > 57 { return -1 } }
		for i in 0 .. nb_text { if input[2 + na_text + i] < 48 || input[2 + na_text + i] > 57 { return -1 } }
		if (na_text > 1 && input[2] == 48) || (nb_text > 1 && input[2 + na_text] == 48) ||
			(nb_text == 1 && input[2 + na_text] == 48) { return -1 }
		mut a := parse_limbs(&input[2], na_text)
		mut b := parse_limbs(&input[2 + na_text], nb_text)
		mut q := [max_limbs]i64{}
		mut r := [max_limbs]i64{}
		na := trim(a, max_limbs); nb := trim(b, max_limbs)
		nq, nr := divide_limbs(a, na, b, nb, mut q, mut r)
		mut result := [max_output]u8{}
		mut bytes := emit(q, nq, mut result, 0)
		result[bytes] = u8(58); bytes++
		bytes = emit(r, nr, mut result, bytes)
		if output == nil || capacity < usize(bytes) { return -2 }
		for i in 0 .. bytes { output[i] = result[i] }
		return i64(bytes)
	}
}
