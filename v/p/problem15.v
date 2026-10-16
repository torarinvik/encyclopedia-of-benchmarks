module problem15

@[export: 'problem15']
pub fn problem15(grid_size i64) i64 {
	if grid_size < 0 || grid_size > 20 { return -1 }
	mut paths := i64(1)
	mut step := i64(1)
	for step <= grid_size {
		paths = paths * (grid_size + step) / step
		step++
	}
	return paths
}
