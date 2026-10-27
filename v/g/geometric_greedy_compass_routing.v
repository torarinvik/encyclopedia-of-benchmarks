module geometric_greedy_compass_routing

const max_n = 8
const max_input = 84
const max_output = 80
const output_values = 10

fn put64(output &u8, position int, value i64) {
	unsafe {
		bits := u64(value)
		for byte in 0 .. 8 { output[position+byte] = u8((bits >> (8*byte)) & 255) }
	}
}
fn angle_better(da i64, la i64, db i64, lb i64) bool {
	if (da >= 0) != (db >= 0) { return da >= 0 }
	left, right := da*da*lb, db*db*la
	if da >= 0 { return left > right }
	return left < right
}
fn angle_equal(da i64, la i64, db i64, lb i64) bool {
	return (da >= 0) == (db >= 0) && da*da*lb == db*db*la
}

@[export: 'geometric_greedy_compass_routing']
pub fn geometric_greedy_compass_routing(input &i64, length usize, output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 12 || length > max_input { return -1 }
		n64, mode, source64, target64 := input[0], input[1], input[2], input[3]
		if n64 < 2 || n64 > max_n || mode < 0 || mode > 1 || source64 < 0 || target64 < 0 || source64 >= n64 || target64 >= n64 { return -1 }
		n, source, target := int(n64), int(source64), int(target64)
		if length != usize(4+2*n+n*n) { return -1 }
		mut x := [max_n]i64{init: 0}
		mut y := [max_n]i64{init: 0}
		adjacency := 4+2*n
		for i in 0 .. n {
			x[i], y[i] = input[4+i], input[4+n+i]
			if x[i] < -8 || x[i] > 8 || y[i] < -8 || y[i] > 8 { return -1 }
			for j in 0 .. i { if x[i] == x[j] && y[i] == y[j] { return -1 } }
		}
		for i in 0 .. n {
			for j in 0 .. n {
				a, b := input[adjacency+i*n+j], input[adjacency+j*n+i]
				if (a != 0 && a != 1) || a != b || (i == j && a != 0) { return -1 }
			}
		}
		if output == nil || capacity < max_output { return -2 }
		mut path := [max_n]int{init: 0}
		mut visited := [max_n]bool{init: false}
		mut count := 1
		path[0] = source; visited[source] = true
		mut current := source
		for current != target && count < n {
			mut best := n
			mut best_dot := i64(0); mut best_len := i64(1); mut best_distance := i64(0)
			tx, ty := x[target]-x[current], y[target]-y[current]
			for vtx in 0 .. n {
				if input[adjacency+current*n+vtx] != 1 { continue }
				mut better := best == n
				dx, dy := x[vtx]-x[current], y[vtx]-y[current]
				if mode == 0 {
					rx, ry := x[vtx]-x[target], y[vtx]-y[target]
					distance := rx*rx+ry*ry
					if !better { better = distance < best_distance || (distance == best_distance && vtx < best) }
					if better { best_distance = distance }
				} else {
					dot, length_sq := dx*tx+dy*ty, dx*dx+dy*dy
					if !better { better = angle_better(dot,length_sq,best_dot,best_len) || (angle_equal(dot,length_sq,best_dot,best_len) && vtx < best) }
					if better { best_dot = dot; best_len = length_sq }
				}
				if better { best = vtx }
			}
			if best == n || visited[best] { break }
			path[count] = best; count++; visited[best] = true; current = best
		}
		mut record := [output_values]i64{init: 0}
		if current == target { record[0] = 1 }
		record[1] = i64(count-1)
		for i in 0 .. max_n { record[2+i] = -1 }
		for i in 0 .. count { record[2+i] = i64(path[i]) }
		mut staged := [max_output]u8{init: 0}
		for i in 0 .. output_values { put64(&staged[0],8*i,record[i]) }
		for i in 0 .. max_output { output[i] = staged[i] }
		return i64(max_output)
	}
}
