// Uncompiled V ABI draft. Temporary allocation reclamation and recoverable
// allocation errors are unresolved with the current -gc none build.
module symmetric_group_convolution_fft

const sg_prime = i64(998244353)
const sg_factorials = [1, 1, 2, 6, 24, 120, 720, 5040, 40320, 362880]

struct SgColumn {
mut:
	diagonal   i64
	partner    int = -1
	coefficient i64
}

struct SgEmbedding {
	child  int
	offset int
	width  int
}

struct SgRepresentation {
mut:
	shape        [9]int
	basis        [][9]int
	adjacent     [][]SgColumn
	restrictions []SgEmbedding
}

fn sg_free_representations(mut bases []SgRepresentation) {
	for mut rep in bases {
		for mut columns in rep.adjacent { unsafe { columns.free() } }
		unsafe {
			rep.adjacent.free()
			rep.basis.free()
			rep.restrictions.free()
		}
	}
	unsafe { bases.free() }
}

fn sg_free_plan(mut levels [][]SgRepresentation) {
	for mut bases in levels { sg_free_representations(mut bases) }
	unsafe { levels.free() }
}

fn sg_power(base_value i64, exponent_value i64) i64 {
	mut base := base_value
	mut exponent := exponent_value
	mut value := i64(1)
	for exponent > 0 {
		if exponent & 1 != 0 { value = value * base % sg_prime }
		base = base * base % sg_prime
		exponent >>= 1
	}
	return value
}

fn sg_shape_compare(a [9]int, b [9]int) int {
	for i in 0 .. 9 {
		if a[i] < b[i] { return -1 }
		if a[i] > b[i] { return 1 }
	}
	return 0
}

fn sg_tableau_compare(a [9]int, b [9]int, degree int) int {
	for i := degree - 1; i >= 0; i-- {
		if a[i] < b[i] { return -1 }
		if a[i] > b[i] { return 1 }
	}
	return 0
}

fn sg_enumerate(degree int, next int, mut shape [9]int, mut tableau [9]int,
	mut bases []SgRepresentation) {
	if next == degree {
		mut index := 0
		for index < bases.len && sg_shape_compare(bases[index].shape, shape) != 0 { index++ }
		if index == bases.len { bases << SgRepresentation{shape: shape} }
		bases[index].basis << tableau
		return
	}
	for row in 0 .. degree {
		if row > 0 && shape[row] >= shape[row - 1] { continue }
		column := shape[row]
		tableau[next] = row * 9 + column
		shape[row]++
		sg_enumerate(degree, next + 1, mut shape, mut tableau, mut bases)
		shape[row]--
		if column == 0 { break }
	}
}

fn sg_representation_plan(degree int) ?[]SgRepresentation {
	mut shape := [9]int{}
	mut tableau := [9]int{}
	mut bases := []SgRepresentation{}
	mut transferred := false
	defer { if !transferred { sg_free_representations(mut bases) } }
	sg_enumerate(degree, 0, mut shape, mut tableau, mut bases)
	for i in 1 .. bases.len {
		mut j := i
		for j > 0 && sg_shape_compare(bases[j - 1].shape, bases[j].shape) > 0 {
			bases[j - 1], bases[j] = bases[j], bases[j - 1]
			j--
		}
	}
	for r in 0 .. bases.len {
		for i in 1 .. bases[r].basis.len {
			mut j := i
			for j > 0 && sg_tableau_compare(bases[r].basis[j - 1], bases[r].basis[j], degree) > 0 {
				bases[r].basis[j - 1], bases[r].basis[j] = bases[r].basis[j], bases[r].basis[j - 1]
				j--
			}
		}
		for label in 0 .. degree - 1 {
			mut columns := []SgColumn{len: bases[r].basis.len}
			mut columns_transferred := false
			defer { if !columns_transferred { unsafe { columns.free() } } }
			for index, entry in bases[r].basis {
				first, second := entry[label], entry[label + 1]
				distance := second % 9 - second / 9 - first % 9 + first / 9
				if distance == 0 { return none }
				diagonal := sg_power((i64(distance) + sg_prime) % sg_prime, sg_prime - 2)
				mut column := SgColumn{diagonal: diagonal, partner: -1}
				if distance != 1 && distance != -1 {
					mut exchanged := entry
					exchanged[label], exchanged[label + 1] = exchanged[label + 1], exchanged[label]
					mut lo := 0
					mut hi := bases[r].basis.len
					for lo < hi {
						mid := lo + (hi - lo) / 2
						if sg_tableau_compare(bases[r].basis[mid], exchanged, degree) < 0 { lo = mid + 1 } else { hi = mid }
					}
					if lo == bases[r].basis.len || sg_tableau_compare(bases[r].basis[lo], exchanged, degree) != 0 { return none }
					column.partner = lo
					column.coefficient = if distance > 0 { 1 } else { (1 - diagonal * diagonal % sg_prime + sg_prime) % sg_prime }
				}
				columns[index] = column
			}
			bases[r].adjacent << columns
			columns_transferred = true
		}
	}
	transferred = true
	return bases
}

fn sg_make_plan(degree int) ?[][]SgRepresentation {
	if degree < 1 || degree > 9 { return none }
	mut levels := [][]SgRepresentation{len: degree + 1}
	mut transferred := false
	defer { if !transferred { sg_free_plan(mut levels) } }
	for n in 1 .. degree + 1 { levels[n] = sg_representation_plan(n) or { return none } }
	for n in 2 .. degree + 1 {
		for r in 0 .. levels[n].len {
			mut start := 0
			for start < levels[n][r].basis.len {
				corner := levels[n][r].basis[start][n - 1]
				mut end := start + 1
				for end < levels[n][r].basis.len && levels[n][r].basis[end][n - 1] == corner { end++ }
				mut child_shape := levels[n][r].shape
				row := corner / 9
				if row >= 9 || child_shape[row] == 0 { return none }
				child_shape[row]--
				mut child := 0
				for child < levels[n - 1].len && sg_shape_compare(levels[n - 1][child].shape, child_shape) != 0 { child++ }
				if child == levels[n - 1].len || levels[n - 1][child].basis.len != end - start { return none }
				for k in 0 .. end - start {
					for label in 0 .. n - 1 {
						if levels[n][r].basis[start + k][label] != levels[n - 1][child].basis[k][label] { return none }
					}
				}
				levels[n][r].restrictions << SgEmbedding{child: child, offset: start, width: end - start}
				start = end
			}
		}
	}
	transferred = true
	return levels
}

fn sg_rank(permutation [9]int, n int) int {
	mut rank := 0
	for i in 0 .. n {
		mut smaller := 0
		for j in i + 1 .. n {
			if permutation[j] < permutation[i] { smaller++ }
		}
		rank += smaller * sg_factorials[n - 1 - i]
	}
	return rank
}

fn sg_next_permutation(mut values [9]int, n int) bool {
	if n < 2 { return false }
	mut pivot := n - 1
	for pivot > 0 && values[pivot - 1] >= values[pivot] { pivot-- }
	if pivot == 0 { return false }
	mut successor := n - 1
	for values[successor] <= values[pivot - 1] { successor-- }
	values[pivot - 1], values[successor] = values[successor], values[pivot - 1]
	mut left := pivot
	mut right := n - 1
	for left < right {
		values[left], values[right] = values[right], values[left]
		left++
		right--
	}
	return true
}

fn sg_free_blocks(mut blocks [][]i64) {
	for mut block in blocks { unsafe { block.free() } }
	unsafe { blocks.free() }
}

fn sg_apply_generator(generator []SgColumn, source []i64, mut result []i64, transpose bool) bool {
	d := generator.len
	if source.len != d * d || result.len != d * d { return false }
	for i in 0 .. result.len { result[i] = 0 }
	for row, column in generator {
		if column.partner >= d { return false }
		for col in 0 .. d {
			if transpose {
				mut value := column.diagonal * source[row * d + col] % sg_prime
				if column.partner >= 0 { value = (value + column.coefficient * source[column.partner * d + col]) % sg_prime }
				result[row * d + col] = value
			} else {
				value := source[row * d + col]
				index := row * d + col
				result[index] = (result[index] + column.diagonal * value) % sg_prime
				if column.partner >= 0 {
					partner := column.partner * d + col
					result[partner] = (result[partner] + column.coefficient * value) % sg_prime
				}
			}
		}
	}
	return true
}

fn sg_forward(levels [][]SgRepresentation, n int, input []i64) ?[][]i64 {
	if n < 1 || n > 9 || input.len != sg_factorials[n] { return none }
	if n == 1 { return [[input[0]]] }
	mut result := [][]i64{len: levels[n].len}
	mut transferred := false
	defer { if !transferred { sg_free_blocks(mut result) } }
	for shape, rep in levels[n] { result[shape] = []i64{len: rep.basis.len * rep.basis.len} }
	for image in 0 .. n {
		mut restricted := []i64{len: sg_factorials[n - 1]}
		defer { unsafe { restricted.free() } }
		mut h := [9]int{}
		for i in 0 .. n - 1 { h[i] = i }
		mut index := 0
		for {
			mut permutation := h
			permutation[n - 1] = n - 1
			for i in 0 .. n {
				if permutation[i] == image { permutation[i] = n - 1 } else if permutation[i] == n - 1 { permutation[i] = image }
			}
			if index >= restricted.len { return none }
			restricted[index] = input[sg_rank(permutation, n)]
			index++
			if !sg_next_permutation(mut h, n - 1) { break }
		}
		if index != restricted.len { return none }
		mut child := sg_forward(levels, n - 1, restricted) or { return none }
		defer { sg_free_blocks(mut child) }
		for shape, rep in levels[n] {
			d := rep.basis.len
			mut embedded := []i64{len: d * d}
			mut scratch := []i64{len: d * d}
			defer {
				unsafe {
					embedded.free()
					scratch.free()
				}
			}
			for entry in rep.restrictions {
				if entry.child < 0 || entry.child >= child.len || entry.offset < 0 || entry.width < 0 ||
					entry.offset + entry.width > d || child[entry.child].len != entry.width * entry.width { return none }
				for row in 0 .. entry.width {
					for col in 0 .. entry.width {
						embedded[(entry.offset + row) * d + entry.offset + col] = child[entry.child][row * entry.width + col]
					}
				}
			}
			for generator in image .. n - 1 {
				if !sg_apply_generator(rep.adjacent[generator], embedded, mut scratch, false) { return none }
				embedded, scratch = scratch, embedded
			}
			for generator := n - 3; generator >= image; generator-- {
				if !sg_apply_generator(rep.adjacent[generator], embedded, mut scratch, false) { return none }
				embedded, scratch = scratch, embedded
			}
			for i in 0 .. embedded.len { result[shape][i] = (result[shape][i] + embedded[i]) % sg_prime }
		}
	}
	transferred = true
	return result
}

fn sg_invariant_diagonal(rep SgRepresentation) ?[]i64 {
	d := rep.basis.len
	mut weights := []i64{len: d, init: -1}
	mut queue := []int{len: d}
	mut transferred := false
	defer {
		unsafe {
			queue.free()
			if !transferred { weights.free() }
		}
	}
	for start in 0 .. d {
		if weights[start] != -1 { continue }
		weights[start] = 1
		mut head := 0
		mut tail := 1
		queue[0] = start
		for head < tail {
			source := queue[head]
			head++
			for generator in rep.adjacent {
				edge := generator[source]
				if edge.partner < 0 { continue }
				if edge.partner >= d { return none }
				back := generator[edge.partner]
				if back.partner != source || edge.coefficient == 0 || back.coefficient == 0 { return none }
				mut candidate := weights[source] * back.coefficient % sg_prime
				candidate = candidate * sg_power(edge.coefficient, sg_prime - 2) % sg_prime
				if weights[edge.partner] == -1 {
					if tail >= d { return none }
					weights[edge.partner] = candidate
					queue[tail] = edge.partner
					tail++
				} else if weights[edge.partner] != candidate { return none }
			}
		}
	}
	transferred = true
	return weights
}

fn sg_transpose_forward(levels [][]SgRepresentation, n int, gradients [][]i64) ?[]i64 {
	if n < 1 || n > 9 || gradients.len != levels[n].len { return none }
	if n == 1 {
		if gradients[0].len != 1 { return none }
		return [gradients[0][0]]
	}
	mut result := []i64{len: sg_factorials[n]}
	mut transferred := false
	defer { if !transferred { unsafe { result.free() } } }
	for image in 0 .. n {
		mut child := [][]i64{len: levels[n - 1].len}
		defer { sg_free_blocks(mut child) }
		for shape, rep in levels[n - 1] { child[shape] = []i64{len: rep.basis.len * rep.basis.len} }
		for shape, rep in levels[n] {
			d := rep.basis.len
			if gradients[shape].len != d * d { return none }
			mut current := gradients[shape].clone()
			mut scratch := []i64{len: d * d}
			defer {
				unsafe {
					current.free()
					scratch.free()
				}
			}
			for generator in image .. n - 1 {
				if !sg_apply_generator(rep.adjacent[generator], current, mut scratch, true) { return none }
				current, scratch = scratch, current
			}
			for generator := n - 3; generator >= image; generator-- {
				if !sg_apply_generator(rep.adjacent[generator], current, mut scratch, true) { return none }
				current, scratch = scratch, current
			}
			for entry in rep.restrictions {
				if entry.child < 0 || entry.child >= child.len || entry.offset < 0 || entry.width < 0 ||
					entry.offset + entry.width > d || child[entry.child].len != entry.width * entry.width { return none }
				for row in 0 .. entry.width {
					for col in 0 .. entry.width {
						target := row * entry.width + col
						child[entry.child][target] = (child[entry.child][target] +
							current[(entry.offset + row) * d + entry.offset + col]) % sg_prime
					}
				}
			}
		}
		mut restricted := sg_transpose_forward(levels, n - 1, child) or { return none }
		defer { unsafe { restricted.free() } }
		mut h := [9]int{}
		for i in 0 .. n - 1 { h[i] = i }
		mut index := 0
		for {
			mut permutation := h
			permutation[n - 1] = n - 1
			for i in 0 .. n {
				if permutation[i] == image { permutation[i] = n - 1 } else if permutation[i] == n - 1 { permutation[i] = image }
			}
			if index >= restricted.len { return none }
			result[sg_rank(permutation, n)] = restricted[index]
			index++
			if !sg_next_permutation(mut h, n - 1) { break }
		}
		if index != restricted.len { return none }
	}
	transferred = true
	return result
}

fn sg_inverse(levels [][]SgRepresentation, n int, blocks [][]i64) ?[]i64 {
	if n < 1 || n > 9 || blocks.len != levels[n].len { return none }
	if n == 1 {
		if blocks[0].len != 1 { return none }
		return [blocks[0][0]]
	}
	inverse_order := sg_power(i64(sg_factorials[n]), sg_prime - 2)
	mut weighted := [][]i64{len: levels[n].len}
	defer { sg_free_blocks(mut weighted) }
	for shape, rep in levels[n] {
		d := rep.basis.len
		if blocks[shape].len != d * d { return none }
		mut diagonal := sg_invariant_diagonal(rep) or { return none }
		mut inverse_diagonal := []i64{len: d}
		defer {
			unsafe {
				diagonal.free()
				inverse_diagonal.free()
			}
		}
		for i in 0 .. d { inverse_diagonal[i] = sg_power(diagonal[i], sg_prime - 2) }
		weighted[shape] = []i64{len: d * d}
		for row in 0 .. d {
			for col in 0 .. d {
				mut value := blocks[shape][row * d + col] * i64(d) % sg_prime
				value = value * inverse_order % sg_prime
				value = value * diagonal[row] % sg_prime
				weighted[shape][row * d + col] = value * inverse_diagonal[col] % sg_prime
			}
		}
	}
	return sg_transpose_forward(levels, n, weighted)
}

@[export: 'symmetric_group_convolution_fft']
pub fn symmetric_group_convolution_fft(input &i64, length usize, output &u8, capacity usize) i64 {
	unsafe {
		if isnil(input) || length < 1 || length > 725762 { return -1 }
		if input[0] < 1 || input[0] > 9 { return -1 }
		n := int(input[0])
		count := sg_factorials[n]
		if length != usize(1 + 2 * count) { return -1 }
		for i in 1 .. int(length) {
			if input[i] < 0 || input[i] >= sg_prime { return -1 }
		}
		if isnil(output) || capacity < usize(4 * count) { return -2 }
		mut left_input := []i64{len: count}
		mut right_input := []i64{len: count}
		defer {
			left_input.free()
			right_input.free()
		}
		for i in 0 .. count {
			left_input[i] = input[1 + i]
			right_input[i] = input[1 + count + i]
		}
		mut levels := sg_make_plan(n) or { return -4 }
		defer { sg_free_plan(mut levels) }
		mut left := sg_forward(levels, n, left_input) or { return -4 }
		defer { sg_free_blocks(mut left) }
		mut right := sg_forward(levels, n, right_input) or { return -4 }
		defer { sg_free_blocks(mut right) }
		mut product := [][]i64{len: levels[n].len}
		defer { sg_free_blocks(mut product) }
		for shape, rep in levels[n] {
			d := rep.basis.len
			product[shape] = []i64{len: d * d}
			for row in 0 .. d {
				for inner in 0 .. d {
					for col in 0 .. d {
						index := row * d + col
						product[shape][index] = (product[shape][index] +
							left[shape][row * d + inner] * right[shape][inner * d + col]) % sg_prime
					}
				}
			}
		}
		mut coefficients := sg_inverse(levels, n, product) or { return -4 }
		defer { coefficients.free() }
		if coefficients.len != count { return -4 }
		for i in 0 .. count {
			value := u32(coefficients[i])
			for byte in 0 .. 4 { output[4 * i + byte] = u8((value >> (8 * byte)) & 255) }
		}
		return i64(4 * count)
	}
}
