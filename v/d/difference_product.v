// Independent difference-product V draft; see package README.
// Registered draft; compilation and output remain unverified.
module difference_product

const prime = i64(998244353)

fn dp_power(value i64, exponent_value i64) i64 {
	mut base := value
	mut exponent := exponent_value
	mut result := i64(1)
	for exponent > 0 {
		if exponent & 1 != 0 { result = result * base % prime }
		base = base * base % prime
		exponent >>= 1
	}
	return result
}

fn dp_transform(mut values []i64, inverse bool) {
	n := values.len
	mut reversed := 0
	for i in 1 .. n {
		mut bit := n >> 1
		for reversed & bit != 0 { reversed ^= bit; bit >>= 1 }
		reversed ^= bit
		if i < reversed { values[i], values[reversed] = values[reversed], values[i] }
	}
	mut width := 2
	for width <= n {
		mut step := dp_power(3, (prime - 1) / i64(width))
		if inverse { step = dp_power(step, prime - 2) }
		mut start := 0
		for start < n {
			mut root := i64(1)
			for j in 0 .. width / 2 {
				a := values[start + j]
				b := values[start + j + width / 2] * root % prime
				values[start + j] = (a + b) % prime
				values[start + j + width / 2] = (a - b + prime) % prime
				root = root * step % prime
			}
			start += width
		}
		width *= 2
	}
	if inverse {
		scale := dp_power(i64(n), prime - 2)
		for i in 0 .. n { values[i] = values[i] * scale % prime }
	}
}

fn dp_multiply(left []i64, right []i64) []i64 {
	if left.len == 0 || right.len == 0 { return []i64{} }
	needed := left.len + right.len - 1
	if left.len <= 32 || right.len <= 32 {
		mut result := []i64{len: needed}
		for i in 0 .. left.len {
			for j in 0 .. right.len { result[i + j] = (result[i + j] + left[i] * right[j]) % prime }
		}
		return result
	}
	mut size := 1
	for size < needed { size *= 2 }
	mut a := []i64{len: size}
	mut b := []i64{len: size}
	for i in 0 .. left.len { a[i] = left[i] }
	for i in 0 .. right.len { b[i] = right[i] }
	dp_transform(mut a, false)
	dp_transform(mut b, false)
	for i in 0 .. size { a[i] = a[i] * b[i] % prime }
	dp_transform(mut a, true)
	return a[..needed].clone()
}

fn dp_inverse(poly []i64, count int) []i64 {
	mut inverse := [dp_power(poly[0], prime - 2)]
	for inverse.len < count {
		mut n := 2 * inverse.len
		if n > count { n = count }
		mut prefix_len := poly.len
		if prefix_len > n { prefix_len = n }
		mut correction := dp_multiply(poly[..prefix_len], inverse)
		if correction.len < n { correction << []i64{len: n - correction.len} }
		if correction.len > n { correction = correction[..n].clone() }
		for i in 0 .. n { correction[i] = (prime - correction[i]) % prime }
		correction[0] = (correction[0] + 2) % prime
		product := dp_multiply(inverse, correction)
		inverse = product[..n].clone()
	}
	return inverse
}

fn dp_remainder(dividend []i64, divisor []i64) []i64 {
	if dividend.len < divisor.len { return dividend.clone() }
	if divisor.len == 1 { return []i64{} }
	count := dividend.len - divisor.len + 1
	mut high := []i64{len: count}
	mut reversed := []i64{len: divisor.len}
	for i in 0 .. count { high[i] = dividend[dividend.len - 1 - i] }
	for i in 0 .. divisor.len { reversed[i] = divisor[divisor.len - 1 - i] }
	reciprocal := dp_inverse(reversed, count)
	quotient_reversed := dp_multiply(high, reciprocal)
	mut quotient := []i64{len: count}
	for i in 0 .. count { quotient[i] = quotient_reversed[count - 1 - i] }
	removed := dp_multiply(quotient, divisor)
	mut result := []i64{len: divisor.len - 1}
	for i in 0 .. result.len { result[i] = (dividend[i] - removed[i] + prime) % prime }
	for result.len > 0 && result[result.len - 1] == 0 { result.delete_last() }
	return result
}

fn dp_tree(points []i64) (int, [][]i64) {
	mut size := 1
	for size < points.len { size *= 2 }
	mut nodes := [][]i64{len: 2 * size}
	for i in 0 .. size {
		if i < points.len { nodes[size + i] = [(prime - points[i]) % prime, i64(1)] }
		else { nodes[size + i] = [i64(1)] }
	}
	mut node := size - 1
	for node > 0 {
		nodes[node] = dp_multiply(nodes[2 * node], nodes[2 * node + 1])
		node--
	}
	return size, nodes
}

fn dp_visit(nodes [][]i64, size int, count int, node int, value []i64, mut output []i64) {
	if node >= size {
		index := node - size
		if index < count && value.len > 0 { output[index] = value[0] }
		return
	}
	left := dp_remainder(value, nodes[2 * node])
	right := dp_remainder(value, nodes[2 * node + 1])
	dp_visit(nodes, size, count, 2 * node, left, mut output)
	dp_visit(nodes, size, count, 2 * node + 1, right, mut output)
}

fn dp_ordered(points []i64) i64 {
	if points.len <= 32 {
		mut product := i64(1)
		for i in 0 .. points.len {
			for j in i + 1 .. points.len {
				product = product * ((points[i] - points[j] + prime) % prime) % prime
			}
		}
		return product
	}
	middle := points.len / 2
	left := points[..middle].clone()
	right := points[middle..].clone()
	mut product := dp_ordered(left) * dp_ordered(right) % prime
	if product == 0 { return 0 }
	_, left_tree := dp_tree(left)
	right_size, right_tree := dp_tree(right)
	initial := dp_remainder(left_tree[1], right_tree[1])
	mut values := []i64{len: right.len}
	dp_visit(right_tree, right_size, right.len, 1, initial, mut values)
	for value in values { product = product * value % prime }
	if left.len & 1 != 0 && right.len & 1 != 0 && product != 0 { product = prime - product }
	return product
}

@[export: 'difference_product']
pub fn difference_product(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length == 0 || input[0] < 0 || input[0] > 65536 { return -1 }
		count := int(input[0])
		if length != usize(count + 1) { return -1 }
		mut points := []i64{len: count}
		for i in 0 .. count {
			if input[i + 1] < 0 || input[i + 1] >= prime { return -1 }
			points[i] = input[i + 1]
		}
		return dp_ordered(points)
	}
}
