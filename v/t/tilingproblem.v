module tilingproblem

@[export: 'tilingproblem']
pub fn tilingproblem(input &i64, length usize) i64 {
	if length != 1 || input[0] < 0 || input[0] > 91 { return -1 }
	mut previous := i64(1)
	mut current := i64(1)
	for width := i64(2); width <= input[0]; width++ { next := previous + current; previous = current; current = next }
	return current
}
