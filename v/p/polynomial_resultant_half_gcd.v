// Uncompiled and unexecuted V half-GCD resultant draft.
module polynomial_resultant_half_gcd

const resultant_prime = i64(998244353)

fn resultant_power(value i64, exponent_value i64) i64 {
	mut base := value
	mut exponent := exponent_value
	mut answer := i64(1)
	for exponent > 0 {
		if exponent & 1 != 0 { answer = answer * base % resultant_prime }
		base = base * base % resultant_prime
		exponent >>= 1
	}
	return answer
}

fn resultant_trim(mut a []i64) {
	for a.len > 0 && a[a.len - 1] == 0 { a.delete_last() }
}

fn resultant_ntt(mut a []i64, inverse bool) {
	n := a.len
	mut j := 0
	for i in 1 .. n {
		mut bit := n >> 1
		for j & bit != 0 { j ^= bit; bit >>= 1 }
		j ^= bit
		if i < j { a[i], a[j] = a[j], a[i] }
	}
	mut width := 2
	for width <= n {
		mut step := resultant_power(3, (resultant_prime - 1) / i64(width))
		if inverse { step = resultant_power(step, resultant_prime - 2) }
		mut start := 0
		for start < n {
			mut factor := i64(1)
			for k in 0 .. width / 2 {
				x := a[start + k]
				y := a[start + k + width / 2] * factor % resultant_prime
				a[start + k] = (x + y) % resultant_prime
				a[start + k + width / 2] = (x - y + resultant_prime) % resultant_prime
				factor = factor * step % resultant_prime
			}
			start += width
		}
		width *= 2
	}
	if inverse {
		scale := resultant_power(i64(n), resultant_prime - 2)
		for i in 0 .. n { a[i] = a[i] * scale % resultant_prime }
	}
}

fn resultant_mul(a []i64, b []i64) []i64 {
	if a.len == 0 || b.len == 0 { return []i64{} }
	count := a.len + b.len - 1
	mut output := []i64{len: count}
	if a.len <= 32 || b.len <= 32 {
		for i in 0 .. a.len {
			for j in 0 .. b.len { output[i+j] = (output[i+j] + a[i] * b[j]) % resultant_prime }
		}
	} else {
		mut size := 1
		for size < count { size *= 2 }
		mut x := []i64{len: size}
		mut y := []i64{len: size}
		for i in 0 .. a.len { x[i] = a[i] }
		for i in 0 .. b.len { y[i] = b[i] }
		resultant_ntt(mut x, false)
		resultant_ntt(mut y, false)
		for i in 0 .. size { x[i] = x[i] * y[i] % resultant_prime }
		resultant_ntt(mut x, true)
		for i in 0 .. count { output[i] = x[i] }
	}
	resultant_trim(mut output)
	return output
}

fn resultant_add(a []i64, b []i64) []i64 {
	mut count := a.len
	if b.len > count { count = b.len }
	mut output := []i64{len: count}
	for i in 0 .. a.len { output[i] = a[i] }
	for i in 0 .. b.len { output[i] = (output[i] + b[i]) % resultant_prime }
	resultant_trim(mut output)
	return output
}

// Truncated Newton inversion, with f[0] nonzero.
fn resultant_inverse(f []i64, count int) []i64 {
	mut inverse := [resultant_power(f[0], resultant_prime - 2)]
	for inverse.len < count {
		mut size := 2 * inverse.len
		if size > count { size = count }
		mut prefix_len := f.len
		if prefix_len > size { prefix_len = size }
		mut correction := resultant_mul(f[..prefix_len], inverse)
		if correction.len < size { correction << []i64{len: size - correction.len} }
		if correction.len > size { correction = correction[..size].clone() }
		for i in 0 .. size { correction[i] = (resultant_prime - correction[i]) % resultant_prime }
		correction[0] = (correction[0] + 2) % resultant_prime
		mut product := resultant_mul(inverse, correction)
		if product.len < size { product << []i64{len: size - product.len} }
		inverse = product[..size].clone()
	}
	return inverse
}

fn resultant_divrem(a []i64, b []i64) ([]i64, []i64) {
	if a.len < b.len { return []i64{}, a.clone() }
	count := a.len - b.len + 1
	mut high := []i64{len: count}
	mut reversed := []i64{len: b.len}
	for i in 0 .. count { high[i] = a[a.len - 1 - i] }
	for i in 0 .. b.len { reversed[i] = b[b.len - 1 - i] }
	mut qrev := resultant_mul(high, resultant_inverse(reversed, count))
	if qrev.len < count { qrev << []i64{len: count - qrev.len} }
	mut q := []i64{len: count}
	for i in 0 .. count { q[i] = qrev[count - 1 - i] }
	removed := resultant_mul(q, b)
	mut r := []i64{len: b.len - 1}
	for i in 0 .. r.len {
		mut sub := i64(0)
		if i < removed.len { sub = removed[i] }
		r[i] = (a[i] - sub + resultant_prime) % resultant_prime
	}
	resultant_trim(mut q)
	resultant_trim(mut r)
	return q, r
}

struct ResultantMatrix {
	a []i64
	b []i64
	c []i64
	d []i64
}

struct ResultantHead {
	degree int
	leading i64
}

fn resultant_identity() ResultantMatrix {
	return ResultantMatrix{a: [i64(1)], d: [i64(1)]}
}

fn resultant_step(q []i64) ResultantMatrix {
	mut negative := []i64{len: q.len}
	for i in 0 .. q.len { negative[i] = (resultant_prime - q[i]) % resultant_prime }
	return ResultantMatrix{b: [i64(1)], c: [i64(1)], d: negative}
}

fn resultant_compose(x ResultantMatrix, y ResultantMatrix) ResultantMatrix {
	return ResultantMatrix{
		a: resultant_add(resultant_mul(x.a, y.a), resultant_mul(x.b, y.c))
		b: resultant_add(resultant_mul(x.a, y.b), resultant_mul(x.b, y.d))
		c: resultant_add(resultant_mul(x.c, y.a), resultant_mul(x.d, y.c))
		d: resultant_add(resultant_mul(x.c, y.b), resultant_mul(x.d, y.d))
	}
}

fn resultant_apply(m ResultantMatrix, a []i64, b []i64) ([]i64, []i64) {
	return resultant_add(resultant_mul(m.a, a), resultant_mul(m.b, b)),
		resultant_add(resultant_mul(m.c, a), resultant_mul(m.d, b))
}

fn resultant_upper(a []i64, shift int) []i64 {
	if shift >= a.len { return []i64{} }
	return a[shift..].clone()
}

fn resultant_half(a []i64, b []i64, mut heads []ResultantHead) ResultantMatrix {
	if b.len == 0 { return resultant_identity() }
	degree := a.len - 1
	threshold := (degree + 1) / 2
	if b.len <= threshold { return resultant_identity() }
	if degree <= 64 {
		mut x := a.clone()
		mut y := b.clone()
		mut matrix := resultant_identity()
		for y.len > threshold && y.len > 0 {
			q, r := resultant_divrem(x, y)
			heads << ResultantHead{degree: q.len - 1, leading: q[q.len - 1]}
			matrix = resultant_compose(resultant_step(q), matrix)
			x = y
			y = r
		}
		return matrix
	}
	first := resultant_half(resultant_upper(a, threshold), resultant_upper(b, threshold), mut heads)
	c, d := resultant_apply(first, a, b)
	if d.len == 0 || d.len <= threshold { return first }
	q, r := resultant_divrem(c, d)
	heads << ResultantHead{degree: q.len - 1, leading: q[q.len - 1]}
	prefix := resultant_compose(resultant_step(q), first)
	if r.len == 0 { return prefix }
	shift := 2 * threshold - (d.len - 1)
	upper_r := resultant_upper(r, shift)
	if upper_r.len == 0 { return prefix }
	last := resultant_half(resultant_upper(d, shift), upper_r, mut heads)
	return resultant_compose(last, prefix)
}

fn resultant_value(first []i64, second []i64) i64 {
	mut a := first.clone()
	mut b := second.clone()
	mut answer := i64(1)
	if a.len < b.len {
		if (a.len - 1) & 1 != 0 && (b.len - 1) & 1 != 0 { answer = resultant_prime - answer }
		temp := a
		a = b
		b = temp
	}
	for {
		if b.len == 1 { return answer * resultant_power(b[0], i64(a.len - 1)) % resultant_prime }
		mut heads := []ResultantHead{}
		mut c := []i64{}
		mut d := []i64{}
		if a.len != b.len {
			matrix := resultant_half(a, b, mut heads)
			if heads.len > 0 { c, d = resultant_apply(matrix, a, b) }
		}
		if heads.len == 0 {
			_, r := resultant_divrem(a, b)
			if r.len == 0 { return 0 }
			da := a.len - 1
			db := b.len - 1
			dr := r.len - 1
			if da & 1 != 0 && db & 1 != 0 { answer = resultant_prime - answer }
			answer = answer * resultant_power(b[b.len - 1], i64(da - dr)) % resultant_prime
			a = b
			b = r
		} else {
			if d.len == 0 { return 0 }
			mut da := a.len - 1
			mut db := b.len - 1
			mut lead := b[b.len - 1]
			for i in 0 .. heads.len {
				last := i + 1 == heads.len
				mut dr := d.len - 1
				if !last { dr = db - heads[i + 1].degree }
				if da & 1 != 0 && db & 1 != 0 { answer = resultant_prime - answer }
				answer = answer * resultant_power(lead, i64(da - dr)) % resultant_prime
				if !last { lead = lead * resultant_power(heads[i + 1].leading, resultant_prime - 2) % resultant_prime }
				da = db
				db = dr
			}
			a = c
			b = d
		}
	}
	return answer
}

@[export: 'polynomial_resultant_half_gcd']
pub fn polynomial_resultant_half_gcd(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 4 || length > 100002 { return -1 }
		m := input[0]
		n := input[1]
		if m < 0 || m > 50000 || n < 0 || n > 50000 || m + n > 99998 { return -1 }
		first_count := int(m) + 1
		second_count := int(n) + 1
		if length != usize(first_count + second_count + 2) { return -1 }
		mut a := []i64{len: first_count}
		mut b := []i64{len: second_count}
		for i in 0 .. first_count {
			a[i] = input[2 + i]
			if a[i] < 0 || a[i] >= resultant_prime { return -1 }
		}
		for i in 0 .. second_count {
			b[i] = input[2 + first_count + i]
			if b[i] < 0 || b[i] >= resultant_prime { return -1 }
		}
		if a[a.len - 1] == 0 || b[b.len - 1] == 0 { return -1 }
		return resultant_value(a, b)
	}
}
