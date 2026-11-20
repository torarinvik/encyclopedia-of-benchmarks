module free_polyomino_enumeration

const fp_max_n = 8
const fp_max_shapes = 512
const fp_layer_words = fp_max_shapes * fp_max_n

fn fp_canonical(xs [fp_max_n]i64, ys [fp_max_n]i64, size int) [fp_max_n]i64 {
	mut best := [fp_max_n]i64{}
	mut have_best := false
	for mode in 0 .. 8 {
		mut tx := [fp_max_n]i64{}
		mut ty := [fp_max_n]i64{}
		mut codes := [fp_max_n]i64{}
		mut min_x := i64(1000)
		mut min_y := i64(1000)
		for i in 0 .. size {
			mut a := if mode >= 4 { ys[i] } else { xs[i] }
			mut b := if mode >= 4 { xs[i] } else { ys[i] }
			if (mode & 1) != 0 { a = -a }
			if (mode & 2) != 0 { b = -b }
			tx[i], ty[i] = a, b
			if a < min_x { min_x = a }
			if b < min_y { min_y = b }
		}
		for i in 0 .. size {
			codes[i] = (tx[i] - min_x) * 8 + ty[i] - min_y
			mut j := i
			for j > 0 && codes[j] < codes[j - 1] {
				codes[j], codes[j - 1] = codes[j - 1], codes[j]
				j--
			}
		}
		mut less := !have_best
		if have_best {
			for i in 0 .. size {
				if codes[i] != best[i] { less = codes[i] < best[i]; break }
			}
		}
		if less {
			for i in 0 .. size { best[i] = codes[i] }
			have_best = true
		}
	}
	return best
}

@[export: 'free_polyomino_enumeration']
pub fn free_polyomino_enumeration(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length != 1 { return -1 }
		if input[0] < 1 || input[0] > fp_max_n { return -1 }
		 n := int(input[0])
		mut shapes := [2 * fp_layer_words]i64{}
		mut current := 0
		mut shape_count := 1
		dx := [4]int{1, -1, 0, 0}
		dy := [4]int{0, 0, 1, -1}
		for size in 1 .. n {
			next := 1 - current
			mut next_count := 0
			for s in 0 .. shape_count {
				for cell in 0 .. size {
					code := shapes[current * fp_layer_words + s * fp_max_n + cell]
					x, y := int(code / 8), int(code % 8)
					for direction in 0 .. 4 {
						nx, ny := x + dx[direction], y + dy[direction]
						mut occupied := false
						if nx >= 0 && nx < 8 && ny >= 0 && ny < 8 {
							neighbor := i64(nx * 8 + ny)
							for i in 0 .. size {
								if shapes[current * fp_layer_words + s * fp_max_n + i] == neighbor { occupied = true }
							}
						}
						if occupied { continue }
						mut xs := [fp_max_n]i64{}
						mut ys := [fp_max_n]i64{}
						for i in 0 .. size {
							previous := shapes[current * fp_layer_words + s * fp_max_n + i]
							xs[i], ys[i] = previous / 8, previous % 8
						}
						xs[size], ys[size] = i64(nx), i64(ny)
						candidate := fp_canonical(xs, ys, size + 1)
						mut duplicate := false
						for old in 0 .. next_count {
							if !duplicate {
								mut same := true
								for i in 0 .. size + 1 {
									if shapes[next * fp_layer_words + old * fp_max_n + i] != candidate[i] { same = false }
								}
								if same { duplicate = true }
							}
						}
						if !duplicate {
							if next_count >= fp_max_shapes { return -1 }
							for i in 0 .. size + 1 { shapes[next * fp_layer_words + next_count * fp_max_n + i] = candidate[i] }
							next_count++
						}
					}
				}
			}
			current = next
			shape_count = next_count
		}
		return i64(shape_count)
	}
}
