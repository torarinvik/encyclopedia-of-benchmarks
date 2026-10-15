module pi_approximation

@[export: 'pi_approximation']
pub fn pi_approximation(points &f64, point_count usize) f64 {
	mut inside := u64(0)
	unsafe {
		for index in 0 .. point_count {
			x := points[2 * index]
			y := points[2 * index + 1]
			if x * x + y * y <= 1.0 {
				inside++
			}
		}
	}
	return 4.0 * f64(inside) / f64(point_count)
}
