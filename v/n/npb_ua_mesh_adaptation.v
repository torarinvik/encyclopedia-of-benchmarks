module npb_ua_mesh_adaptation

const depth = 2
const side = 4
const max_cells = 64
const invalid_result = -1.0e300

struct Cell {
	level int
	x int
	y int
	z int
}

fn cell_size(cell Cell) int { return 1 << (depth - cell.level) }

fn overlaps_source(cell Cell, sx int, sy int, sz int, radius int) bool {
	point := [3]int{sx, sy, sz}
	lower := [3]int{cell.x, cell.y, cell.z}
	size := cell_size(cell)
	mut squared := 0
	for axis in 0 .. 3 {
		mut distance := 0
		if point[axis] < lower[axis] { distance = lower[axis] - point[axis] }
		else if point[axis] > lower[axis] + size { distance = point[axis] - lower[axis] - size }
		squared += distance * distance
	}
	return squared < radius * radius
}

fn neighboring(a Cell, b Cell) bool {
	alo := [3]int{a.x, a.y, a.z}
	blo := [3]int{b.x, b.y, b.z}
	asize, bsize := cell_size(a), cell_size(b)
	mut touching := 0
	for axis in 0 .. 3 {
		ahi, bhi := alo[axis] + asize, blo[axis] + bsize
		if ahi == blo[axis] || bhi == alo[axis] { touching++ }
		else if ahi <= blo[axis] || bhi <= alo[axis] { return false }
	}
	return touching == 1 || touching == 2
}

fn split_cell(mut cells []Cell, mut count int, index int) bool {
	parent := cells[index]
	if parent.level >= depth || count + 7 > max_cells { return false }
	child_size := cell_size(parent) / 2
	mut i := count - 1
	for i > index {
		cells[i + 7] = cells[i]
		i--
	}
	mut slot := index
	for bz in 0 .. 2 { for by in 0 .. 2 { for bx in 0 .. 2 {
		cells[slot] = Cell{level: parent.level + 1, x: parent.x + bx * child_size, y: parent.y + by * child_size, z: parent.z + bz * child_size}
		slot++
	}}}
	count += 7
	return true
}

fn balanced(cells []Cell, count int) bool {
	for i in 0 .. count { for j in i + 1 .. count {
		if neighboring(cells[i], cells[j]) && abs(cells[i].level - cells[j].level) > 1 { return false }
	}}
	return true
}

fn balance_mesh(mut cells []Cell, mut count int) bool {
	for {
		mut coarse := -1
		for i in 0 .. count {
			if coarse >= 0 { break }
			for j in i + 1 .. count {
				if neighboring(cells[i], cells[j]) && abs(cells[i].level - cells[j].level) > 1 {
					coarse = if cells[i].level < cells[j].level { i } else { j }
					break
				}
			}
		}
		if coarse < 0 { return true }
		if !split_cell(mut cells, mut count, coarse) { return false }
	}
}

fn is_child(cell Cell, level int, x int, y int, z int, size int) bool {
	return cell.level == level && cell.x >= x && cell.x < x + size && cell.y >= y && cell.y < y + size && cell.z >= z && cell.z < z + size
}

fn coarsen_once(mut cells []Cell, mut count int, sx int, sy int, sz int, radius int) bool {
	for seed in 0 .. count {
		child := cells[seed]
		if child.level == 0 { continue }
		parent_level := child.level - 1
		parent_size := 1 << (depth - parent_level)
		child_size := parent_size / 2
		px, py, pz := child.x / parent_size * parent_size, child.y / parent_size * parent_size, child.z / parent_size * parent_size
		parent := Cell{level: parent_level, x: px, y: py, z: pz}
		if overlaps_source(parent, sx, sy, sz, radius) { continue }
		mut found := [8]int{init: -1}
		for i in 0 .. count {
			if is_child(cells[i], child.level, px, py, pz, parent_size) {
				bx, by, bz := (cells[i].x - px) / child_size, (cells[i].y - py) / child_size, (cells[i].z - pz) / child_size
				found[bx + 2 * by + 4 * bz] = i
			}
		}
		mut complete := true
		for q in 0 .. 8 { if found[q] < 0 { complete = false } }
		if !complete { continue }
		mut safe := true
		for i in 0 .. count {
			mut sibling := false
			for q in 0 .. 8 { if found[q] == i { sibling = true } }
			if !sibling && neighboring(parent, cells[i]) && abs(parent_level - cells[i].level) > 1 { safe = false }
		}
		if !safe { continue }
		mut compact := []Cell{len: max_cells}
		mut compact_count := 0
		mut inserted := false
		for i in 0 .. count {
			mut sibling := false
			for q in 0 .. 8 { if found[q] == i { sibling = true } }
			if !sibling {
				compact[compact_count] = cells[i]
				compact_count++
			} else if !inserted {
				compact[compact_count] = parent
				compact_count++
				inserted = true
			}
		}
		for i in 0 .. compact_count { cells[i] = compact[i] }
		count = compact_count
		return true
	}
	return false
}

fn less_cell(a Cell, b Cell) bool {
	if a.level != b.level { return a.level < b.level }
	if a.z != b.z { return a.z < b.z }
	if a.y != b.y { return a.y < b.y }
	return a.x < b.x
}

@[export: 'npb_ua_mesh_adaptation']
pub fn npb_ua_mesh_adaptation(input &i64, length usize) f64 {
	if unsafe { input == nil } || length < 9 || length > 261 { return invalid_result }
	unsafe {
		for q in 0 .. 3 { if input[q] < 0 || input[q] > side { return invalid_result } }
		if input[3] < 1 || input[3] > side || input[4] < 1 || input[4] > max_cells { return invalid_result }
		sx, sy, sz, radius := int(input[0]), int(input[1]), int(input[2]), int(input[3])
		mut count := int(input[4])
		if length != usize(5 + 4 * count) { return invalid_result }
		mut cells := []Cell{len: max_cells}
		mut covered := [64]bool{}
		for i in 0 .. count {
			lr, xr, yr, zr := input[5 + 4 * i], input[6 + 4 * i], input[7 + 4 * i], input[8 + 4 * i]
			if lr < 0 || lr > depth || xr < 0 || xr > side || yr < 0 || yr > side || zr < 0 || zr > side { return invalid_result }
			cell := Cell{level: int(lr), x: int(xr), y: int(yr), z: int(zr)}
			size := cell_size(cell)
			if cell.x + size > side || cell.y + size > side || cell.z + size > side || cell.x % size != 0 || cell.y % size != 0 || cell.z % size != 0 { return invalid_result }
			cells[i] = cell
			for z in cell.z .. cell.z + size { for y in cell.y .. cell.y + size { for x in cell.x .. cell.x + size {
				q := x + side * (y + side * z)
				if covered[q] { return invalid_result }
				covered[q] = true
			}}}
		}
		for q in 0 .. max_cells { if !covered[q] { return invalid_result } }
		if !balanced(cells, count) { return invalid_result }
		mut i := 0
		for i < count {
			if cells[i].level < depth && overlaps_source(cells[i], sx, sy, sz, radius) {
				if !split_cell(mut cells, mut count, i) { return invalid_result }
			} else { i++ }
		}
		if !balance_mesh(mut cells, mut count) { return invalid_result }
		for coarsen_once(mut cells, mut count, sx, sy, sz, radius) {}
		if !balance_mesh(mut cells, mut count) { return invalid_result }
		for i in 1 .. count {
			key := cells[i]
			mut j := i
			for j > 0 && less_cell(key, cells[j - 1]) { cells[j] = cells[j - 1]; j-- }
			cells[j] = key
		}
		mut checksum := f64(0)
		for q in 0 .. count {
			code := cells[q].level * 1000 + cells[q].x * 100 + cells[q].y * 10 + cells[q].z
			checksum += f64(q + 1) * f64(code)
		}
		return checksum
	}
}
