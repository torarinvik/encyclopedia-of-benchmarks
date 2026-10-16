package problem15

@(export)
problem15 :: proc "c" (grid_size: i64) -> i64 {
	if grid_size < 0 || grid_size > 20 do return -1
	paths := i64(1)
	for step := i64(1); step <= grid_size; step += 1 {
		paths = paths * (grid_size + step) / step
	}
	return paths
}
