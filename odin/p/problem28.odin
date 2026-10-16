package problem28

@(export)
problem28 :: proc "c" (size: i64) -> i64 {
	if size < 0 || size > 100000 do return -1
	total := i64(1)
	layer_count := (size + 1) / 2
	for layer := i64(1); layer < layer_count; layer += 1 {
		odd_corner := 2 * layer + 1
		even_corner := 2 * layer
		total += 4 * odd_corner * odd_corner - 6 * even_corner
	}
	return total
}
