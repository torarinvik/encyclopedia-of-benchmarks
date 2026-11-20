module wave_function_collapse_simple_tiled

const max_cells = 16
const max_tiles = 4
const max_compatibility = 4 * max_tiles
const max_parseable_input_length = 56

fn popcount_small(mask u8) int {
	mut bits := mask
	mut count := 0
	for bits != 0 {
		bits &= bits - 1
		count++
	}
	return count
}

fn propagate(mut domains [max_cells]u8, compatibility [max_compatibility]u8,
	width int, height int, tile_count int, start_cell int, seed_all bool) bool {
	cell_count := width * height
	mut queue := [max_cells]int{}
	mut in_queue := [max_cells]bool{}
	mut head := 0
	mut tail := 0
	mut queued := 0
	if seed_all {
		for cell in 0 .. cell_count {
			queue[tail] = cell
			tail = (tail + 1) % cell_count
			queued++
			in_queue[cell] = true
		}
	} else {
		queue[tail] = start_cell
		tail = (tail + 1) % cell_count
		queued++
		in_queue[start_cell] = true
	}
	for queued != 0 {
		source := queue[head]
		head = (head + 1) % cell_count
		queued--
		in_queue[source] = false
		row := source / width
		column := source % width
		for direction in 0 .. 4 {
			mut neighbor := 0
			mut has_neighbor := false
			if direction == 0 && row != 0 {
				neighbor = source - width
				has_neighbor = true
			} else if direction == 1 && column + 1 < width {
				neighbor = source + 1
				has_neighbor = true
			} else if direction == 2 && row + 1 < height {
				neighbor = source + width
				has_neighbor = true
			} else if direction == 3 && column != 0 {
				neighbor = source - 1
				has_neighbor = true
			}
			if !has_neighbor { continue }
			mut supported := u8(0)
			for tile in 0 .. tile_count {
				if domains[source] & u8(1 << tile) != 0 {
					supported |= compatibility[direction * tile_count + tile]
				}
			}
			reduced := domains[neighbor] & supported
			if reduced == domains[neighbor] { continue }
			domains[neighbor] = reduced
			if reduced == 0 { return false }
			if !in_queue[neighbor] {
				queue[tail] = neighbor
				tail = (tail + 1) % cell_count
				queued++
				in_queue[neighbor] = true
			}
		}
	}
	return true
}

@[export: 'wave_function_collapse_simple_tiled']
pub fn wave_function_collapse_simple_tiled(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 3 || length > max_parseable_input_length { return -1 }
		if input[0] < 1 || input[0] > 4 || input[1] < 1 || input[1] > 4 || input[2] < 1 || input[2] > max_tiles { return -1 }
		width := int(input[0])
		height := int(input[1])
		tile_count := int(input[2])
		cell_count := width * height
		if length != usize(3 + 2 * cell_count + 5 * tile_count) { return -1 }
		full_mask := u8((1 << tile_count) - 1)
		mut domains := [max_cells]u8{}
		mut weights := [max_tiles]u8{}
		mut compatibility := [max_compatibility]u8{}
		mut draws := [max_cells]u16{}
		mut position := 3
		for cell in 0 .. cell_count {
			value := input[position]
			if value < 1 || value > i64(full_mask) { return -1 }
			domains[cell] = u8(value)
			position++
		}
		for tile in 0 .. tile_count {
			value := input[position]
			if value < 1 || value > 4 { return -1 }
			weights[tile] = u8(value)
			position++
		}
		for direction in 0 .. 4 {
			for tile in 0 .. tile_count {
				value := input[position]
				if value < 0 || value > i64(full_mask) { return -1 }
				compatibility[direction * tile_count + tile] = u8(value)
				position++
			}
		}
		for cell in 0 .. cell_count {
			value := input[position]
			if value < 0 || value > 65535 { return -1 }
			draws[cell] = u16(value)
			position++
		}
		for first in 0 .. tile_count {
			for second in 0 .. tile_count {
				north := compatibility[first] & u8(1 << second) != 0
				south_reverse := compatibility[2 * tile_count + second] & u8(1 << first) != 0
				east := compatibility[tile_count + first] & u8(1 << second) != 0
				west_reverse := compatibility[3 * tile_count + second] & u8(1 << first) != 0
				if north != south_reverse || east != west_reverse { return -1 }
			}
		}
		if !propagate(mut domains, compatibility, width, height, tile_count, 0, true) { return -2 }
		for {
			mut best_cell := cell_count
			mut best_count := max_tiles + 1
			for cell in 0 .. cell_count {
				count := popcount_small(domains[cell])
				if count > 1 && count < best_count {
					best_cell = cell
					best_count = count
				}
			}
			if best_cell == cell_count { break }
			mut total_weight := 0
			for tile in 0 .. tile_count {
				if domains[best_cell] & u8(1 << tile) != 0 { total_weight += int(weights[tile]) }
			}
			mut rank := int(draws[best_cell]) * total_weight / 65536
			mut selected := tile_count
			for tile in 0 .. tile_count {
				if domains[best_cell] & u8(1 << tile) == 0 { continue }
				if rank < int(weights[tile]) {
					selected = tile
					break
				}
				rank -= int(weights[tile])
			}
			if selected == tile_count { return -2 }
			domains[best_cell] = u8(1 << selected)
			if !propagate(mut domains, compatibility, width, height, tile_count, best_cell, false) { return -2 }
		}
		mut result := i64(1) << 32
		for cell in 0 .. cell_count {
			tile := 0
			for domains[cell] & u8(1 << tile) == 0 { tile++ }
			result |= i64(tile) << (2 * cell)
		}
		return result
	}
}
