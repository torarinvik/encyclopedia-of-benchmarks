module max_points_on_a_line

const max_n = 16
const max_input = 34
const table_size = 32

fn gcd_positive(a_value int, b_value int) int {
	mut a, mut b := a_value, b_value
	for b != 0 { remainder := a % b; a = b; b = remainder }
	return a
}

@[export: 'max_points_on_a_line']
pub fn max_points_on_a_line(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 3 || length > max_input { return -1 }
	n_value := input[0]
	if n_value < 1 || n_value > max_n || length != usize(1 + 2 * n_value) { return -1 }
	n := int(n_value)
	mut xs := []int{len: max_n, init: 0}
	mut ys := []int{len: max_n, init: 0}
	for i in 0 .. n {
		xv, yv := input[1 + 2 * i], input[2 + 2 * i]
		if xv < -100 || xv > 100 || yv < -100 || yv > 100 { return -1 }
		xs[i], ys[i] = int(xv), int(yv)
		for j in 0 .. i { if xs[i] == xs[j] && ys[i] == ys[j] { return -1 } }
	}
	if n == 1 { return 1 }
	mut answer := i64(2)
	for anchor in 0 .. n {
		mut keys := []int{len: table_size, init: -1}
		mut counts := []int{len: table_size, init: 0}
		mut best := 0
		for other in 0 .. n {
			if other == anchor { continue }
			mut dx, mut dy := xs[other] - xs[anchor], ys[other] - ys[anchor]
			divisor := gcd_positive(abs(dx), abs(dy))
			dx, dy = dx / divisor, dy / divisor
			if dx < 0 || (dx == 0 && dy < 0) { dx, dy = -dx, -dy }
			direction_key := dx * 401 + dy + 200
			mut slot := direction_key % table_size
			for keys[slot] != -1 && keys[slot] != direction_key { slot = (slot + 1) % table_size }
			if keys[slot] == -1 { keys[slot] = direction_key }
			counts[slot]++
			best = max(best, counts[slot])
		}
		answer = max(answer, i64(best + 1))
	}
	return answer
}
