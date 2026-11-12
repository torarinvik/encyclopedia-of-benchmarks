module schreier_sims

const max_n = 6
const max_generators = 4
const max_queries = 8
const max_input = 76
const max_strong_generators = 32
const max_pending = 8192

struct Layer {
mut:
	generators [max_strong_generators]u32
	generator_count int
	in_orbit [max_n]bool
	orbit [max_n]int
	orbit_count int
	transversal [max_n]u32
}

struct Pending {
	level int
	value u32
}

fn identity(n int) u32 {
	mut result := u32(0)
	mut place := u32(1)
	for point in 0 .. n {
		result += u32(point + 1) * place
		place *= u32(7)
	}
	return result
}

fn encode(images [max_n]int, n int) u32 {
	mut result := u32(0)
	mut place := u32(1)
	for point in 0 .. n {
		result += u32(images[point] + 1) * place
		place *= u32(7)
	}
	return result
}

fn image_of(value_input u32, point_input int) int {
	mut value := value_input
	mut point := point_input
	for point > 0 { value /= u32(7); point-- }
	return int(value % u32(7)) - 1
}

fn compose(first u32, second u32, n int) u32 {
	mut images := [max_n]int{}
	for point in 0 .. n { images[point] = image_of(second, image_of(first, point)) }
	return encode(images, n)
}

fn inverse(value u32, n int) u32 {
	mut images := [max_n]int{}
	for point in 0 .. n { images[image_of(value, point)] = point }
	return encode(images, n)
}

fn append_generator(mut layers [max_n]Layer, level int, value u32) bool {
	for i in 0 .. layers[level].generator_count {
		if layers[level].generators[i] == value { return true }
	}
	if layers[level].generator_count >= max_strong_generators { return false }
	layers[level].generators[layers[level].generator_count] = value
	layers[level].generator_count++
	return true
}

fn rebuild_orbit(mut layers [max_n]Layer, level int, n int, id u32) {
	for point in 0 .. n { layers[level].in_orbit[point] = false }
	layers[level].orbit_count = 1
	layers[level].orbit[0] = level
	layers[level].in_orbit[level] = true
	layers[level].transversal[level] = id
	mut at := 0
	for at < layers[level].orbit_count {
		point := layers[level].orbit[at]
		at++
		representative := layers[level].transversal[point]
		for g in 0 .. layers[level].generator_count {
			generator := layers[level].generators[g]
			image := image_of(generator, point)
			if !layers[level].in_orbit[image] {
				layers[level].in_orbit[image] = true
				layers[level].transversal[image] = compose(representative, generator, n)
				layers[level].orbit[layers[level].orbit_count] = image
				layers[level].orbit_count++
			}
		}
	}
}

fn build_chain(mut layers [max_n]Layer, n int, generators [max_generators]u32, count int) bool {
	id := identity(n)
	mut pending := [max_pending]Pending{}
	mut head := 0
	mut tail := 0
	for i in 0 .. count { pending[tail] = Pending{level: 0, value: generators[i]}; tail++ }
	for head < tail {
		item := pending[head]
		head++
		mut residue := item.value
		mut level := item.level
		for level < n {
			image := image_of(residue, level)
			if !layers[level].in_orbit[image] { break }
			residue = compose(residue, inverse(layers[level].transversal[image], n), n)
			level++
		}
		if residue == id || level == n { continue }
		inv := inverse(residue, n)
		if !append_generator(mut layers, level, residue) || !append_generator(mut layers, level, inv) { return false }
		rebuild_orbit(mut layers, level, n, id)
		if level + 1 < n {
			orbit_count := layers[level].orbit_count
			generator_count := layers[level].generator_count
			for orbit_index in 0 .. orbit_count {
				point := layers[level].orbit[orbit_index]
				representative := layers[level].transversal[point]
				for g in 0 .. generator_count {
					generator := layers[level].generators[g]
					image := image_of(generator, point)
					schreier := compose(compose(representative, generator, n), inverse(layers[level].transversal[image], n), n)
					if schreier != id {
						if tail >= max_pending { return false }
						pending[tail] = Pending{level: level + 1, value: schreier}
						tail++
					}
				}
			}
		}
	}
	return true
}

fn is_member(layers [max_n]Layer, value_input u32, n int) bool {
	mut residue := value_input
	id := identity(n)
	for level in 0 .. n {
		image := image_of(residue, level)
		if !layers[level].in_orbit[image] { return false }
		residue = compose(residue, inverse(layers[level].transversal[image], n), n)
	}
	return residue == id
}

fn read_permutation(input &i64, offset int, n int) ?u32 {
	mut used := [max_n]bool{}
	mut images := [max_n]int{}
	unsafe {
		for point in 0 .. n {
			image := input[offset + point]
			if image < 0 || image >= i64(n) || used[int(image)] { return none }
			used[int(image)] = true
			images[point] = int(image)
		}
	}
	return encode(images, n)
}

fn store_le(mut output &u8, offset int, value i64) {
	unsafe {
		mut bits := u64(value)
		for byte in 0 .. 8 { output[offset + byte] = u8(bits & 255); bits >>= 8 }
	}
}

@[export: 'schreier_sims']
pub fn schreier_sims(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 3 || length > max_input { return -1 }
	unsafe {
		nv := input[0]; mv := input[1]; qv := input[2]
		if nv < 1 || nv > max_n || mv < 0 || mv > max_generators || qv < 1 || qv > max_queries { return -1 }
		n := int(nv); m := int(mv); q := int(qv)
		if length != usize(3 + n * (m + q)) { return -1 }
		mut generators := [max_generators]u32{}
		mut queries := [max_queries]u32{}
		mut cursor := 3
		for i in 0 .. m {
			generators[i] = read_permutation(input, cursor, n) or { return -1 }
			cursor += n
		}
		for i in 0 .. q {
			queries[i] = read_permutation(input, cursor, n) or { return -1 }
			cursor += n
		}
		required := 8 * (q + 1)
		if unsafe { output == nil } || capacity < usize(required) { return -2 }
		mut layers := [max_n]Layer{}
		id := identity(n)
		for level in 0 .. n {
			layers[level].in_orbit[level] = true
			layers[level].orbit[0] = level
			layers[level].orbit_count = 1
			layers[level].transversal[level] = id
		}
		if !build_chain(mut layers, n, generators, m) { return -1 }
		mut order := i64(1)
		for level in 0 .. n { order *= i64(layers[level].orbit_count) }
		store_le(mut output, 0, order)
		for i in 0 .. q {
			membership := if is_member(layers, queries[i], n) { i64(1) } else { i64(0) }
			store_le(mut output, 8 * (i + 1), membership)
		}
		return i64(required)
	}
}
