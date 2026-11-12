module sort_points_by_argument

const max_n = 64
const input_max = 129

fn point_half(x i64, y i64) int {
	if y < 0 { return 0 }
	if y == 0 && x >= 0 { return 1 }
	return 2
}

fn point_less(ax i64, ay i64, bx i64, by i64) bool {
	ah, bh := point_half(ax, ay), point_half(bx, by)
	if ah != bh { return ah < bh }
	cross := ax*by - ay*bx
	if cross != 0 { return cross > 0 }
	ra, rb := ax*ax+ay*ay, bx*bx+by*by
	if ra != rb { return ra < rb }
	if ax != bx { return ax < bx }
	return ay < by
}

fn store_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	unsafe { for byte in 0 .. 8 { output[offset+byte] = u8((bits >> (8*byte)) & 255) } }
}

@[export: 'sort_points_by_argument']
pub fn sort_points_by_argument(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 1 || length > input_max { return -1 }
		nr := input[0]
		if nr < 1 || nr > max_n || length != usize(1+2*nr) { return -1 }
		n := int(nr)
		mut xs := [max_n]i64{}
		mut ys := [max_n]i64{}
		for i in 0 .. n {
			x, y := input[1+2*i], input[2+2*i]
			if x < -1_000_000_000 || x > 1_000_000_000 || y < -1_000_000_000 || y > 1_000_000_000 { return -1 }
			xs[i], ys[i] = x, y
		}
		required := 16*n
		if output == nil || capacity < usize(required) { return -2 }
		for i in 1 .. n {
			item_x, item_y := xs[i], ys[i]
			mut j := i
			for j > 0 && point_less(item_x, item_y, xs[j-1], ys[j-1]) {
				xs[j], ys[j] = xs[j-1], ys[j-1]
				j--
			}
			xs[j], ys[j] = item_x, item_y
		}
		for i in 0 .. n { store_le(mut output, 16*i, xs[i]); store_le(mut output, 16*i+8, ys[i]) }
		return i64(required)
	}
}
