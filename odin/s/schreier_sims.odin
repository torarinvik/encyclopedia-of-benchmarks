package schreier_sims

import "core:c"

MAX_N :: 6
MAX_GENERATORS :: 4
MAX_QUERIES :: 8
MAX_INPUT :: 76
MAX_STRONG_GENERATORS :: 32
MAX_PENDING :: 8192
Code :: u32

Layer :: struct {
	generators: [MAX_STRONG_GENERATORS]Code,
	generator_count: int,
	in_orbit: [MAX_N]bool,
	orbit: [MAX_N]int,
	orbit_count: int,
	transversal: [MAX_N]Code,
}
Pending :: struct { level: int, value: Code }

identity :: proc "contextless" (n: int) -> Code {
	result: Code = 0
	place: Code = 1
	for point := 0; point < n; point += 1 { result += Code(point + 1) * place; place *= 7 }
	return result
}
encode :: proc "contextless" (images: ^[MAX_N]int, n: int) -> Code {
	result: Code = 0
	place: Code = 1
	for point := 0; point < n; point += 1 { result += Code(images^[point] + 1) * place; place *= 7 }
	return result
}
image_of :: proc "contextless" (value_input: Code, point_input: int) -> int {
	value := value_input
	point := point_input
	for point > 0 { value /= 7; point -= 1 }
	return int(value % 7) - 1
}
compose :: proc "contextless" (first, second: Code, n: int) -> Code {
	images: [MAX_N]int
	for point := 0; point < n; point += 1 { images[point] = image_of(second, image_of(first, point)) }
	return encode(&images, n)
}
inverse :: proc "contextless" (value: Code, n: int) -> Code {
	images: [MAX_N]int
	for point := 0; point < n; point += 1 { images[image_of(value, point)] = point }
	return encode(&images, n)
}
append_generator :: proc "contextless" (layer: ^Layer, value: Code) -> bool {
	for i := 0; i < layer^.generator_count; i += 1 { if layer^.generators[i] == value do return true }
	if layer^.generator_count >= MAX_STRONG_GENERATORS do return false
	layer^.generators[layer^.generator_count] = value
	layer^.generator_count += 1
	return true
}
rebuild_orbit :: proc "contextless" (layer: ^Layer, base, n: int, id: Code) {
	for point := 0; point < n; point += 1 { layer^.in_orbit[point] = false }
	layer^.orbit_count = 1
	layer^.orbit[0] = base
	layer^.in_orbit[base] = true
	layer^.transversal[base] = id
	at := 0
	for at < layer^.orbit_count {
		point := layer^.orbit[at]
		at += 1
		representative := layer^.transversal[point]
		for g := 0; g < layer^.generator_count; g += 1 {
			generator := layer^.generators[g]
			image := image_of(generator, point)
			if !layer^.in_orbit[image] {
				layer^.in_orbit[image] = true
				layer^.transversal[image] = compose(representative, generator, n)
				layer^.orbit[layer^.orbit_count] = image
				layer^.orbit_count += 1
			}
		}
	}
}
build_chain :: proc "contextless" (layers: ^[MAX_N]Layer, n: int,
		generators: ^[MAX_GENERATORS]Code, count: int) -> bool {
	id := identity(n)
	pending: [MAX_PENDING]Pending
	head := 0
	tail := 0
	for i := 0; i < count; i += 1 { pending[tail] = {0, generators^[i]}; tail += 1 }
	for head < tail {
		item := pending[head]
		head += 1
		residue := item.value
		level := item.level
		for level < n {
			image := image_of(residue, level)
			layer := &layers^[level]
			if !layer^.in_orbit[image] do break
			residue = compose(residue, inverse(layer^.transversal[image], n), n)
			level += 1
		}
		if residue == id || level == n do continue
		layer := &layers^[level]
		inv := inverse(residue, n)
		if !append_generator(layer, residue) || !append_generator(layer, inv) do return false
		rebuild_orbit(layer, level, n, id)
		if level + 1 < n {
			orbit_count := layer^.orbit_count
			generator_count := layer^.generator_count
			for orbit_index := 0; orbit_index < orbit_count; orbit_index += 1 {
				point := layer^.orbit[orbit_index]
				representative := layer^.transversal[point]
				for g := 0; g < generator_count; g += 1 {
					generator := layer^.generators[g]
					image := image_of(generator, point)
					schreier := compose(compose(representative, generator, n), inverse(layer^.transversal[image], n), n)
					if schreier != id {
						if tail >= MAX_PENDING do return false
						pending[tail] = {level + 1, schreier}
						tail += 1
					}
				}
			}
		}
	}
	return true
}
is_member :: proc "contextless" (layers: ^[MAX_N]Layer, value_input: Code, n: int) -> bool {
	id := identity(n)
	residue := value_input
	for level := 0; level < n; level += 1 {
		image := image_of(residue, level)
		layer := &layers^[level]
		if !layer^.in_orbit[image] do return false
		residue = compose(residue, inverse(layer^.transversal[image], n), n)
	}
	return residue == id
}
read_permutation :: proc "contextless" (input: [^]i64, offset, n: int, result: ^Code) -> bool {
	used: [MAX_N]bool
	images: [MAX_N]int
	for point := 0; point < n; point += 1 {
		image := input[offset + point]
		if image < 0 || image >= i64(n) || used[int(image)] do return false
		used[int(image)] = true
		images[point] = int(image)
	}
	result^ = encode(&images, n)
	return true
}
store_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[offset + byte] = u8(bits & 255); bits >>= 8 }
}

@(export)
schreier_sims :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 3 || length > MAX_INPUT do return -1
	nv := input[0]; mv := input[1]; qv := input[2]
	if nv < 1 || nv > i64(MAX_N) || mv < 0 || mv > i64(MAX_GENERATORS) || qv < 1 || qv > i64(MAX_QUERIES) do return -1
	n := int(nv); m := int(mv); q := int(qv)
	if length != c.size_t(3 + n * (m + q)) do return -1
	 generators: [MAX_GENERATORS]Code
	queries: [MAX_QUERIES]Code
	cursor := 3
	for i := 0; i < m; i += 1 {
		if !read_permutation(input, cursor, n, &generators[i]) do return -1
		cursor += n
	}
	for i := 0; i < q; i += 1 {
		if !read_permutation(input, cursor, n, &queries[i]) do return -1
		cursor += n
	}
	required := 8 * (q + 1)
	if output == nil || capacity < c.size_t(required) do return -2
	layers: [MAX_N]Layer
	id := identity(n)
	for level := 0; level < n; level += 1 {
		layers[level].in_orbit[level] = true
		layers[level].orbit[0] = level
		layers[level].orbit_count = 1
		layers[level].transversal[level] = id
	}
	if !build_chain(&layers, n, &generators, m) do return -1
	order := i64(1)
	for level := 0; level < n; level += 1 { order *= i64(layers[level].orbit_count) }
	store_le(output, 0, order)
	for i := 0; i < q; i += 1 {
		membership := i64(0)
		if is_member(&layers, queries[i], n) do membership = 1
		store_le(output, 8 * (i + 1), membership)
	}
	return i64(required)
}
