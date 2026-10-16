module main

fn reverse_points(mut out []i64, start int, count int) {
	for i in 0 .. count / 2 {
		a := start + 2 * i
		b := start + 2 * (count - 1 - i)
		x := out[a]
		y := out[a + 1]
		out[a] = out[b]
		out[a + 1] = out[b + 1]
		out[b] = x
		out[b + 1] = y
	}
}
fn curve(x i64, y i64, side i64, level int, angle int, mut out []i64, off int) int {
	q := side / 4
	p := [[2]i64{ x + q, y + q }, [2]i64{ x - q, y + q }, [2]i64{ x - q, y - q }, [2]i64{ x + q, y - q }]
	a := ((angle % 4) + 4) % 4
	mut r := [4][2]i64{}
	for i in 0 .. 4 { r[i] = p[(i + a) % 4] }
	if level == 1 {
		for i in 0 .. 4 { out[off + 2 * i] = r[i][0]; out[off + 2 * i + 1] = r[i][1] }
		return 4
	}
	h := side / 2
	n := curve(r[0][0], r[0][1], h, level - 1, a + 1, mut out, off)
	reverse_points(mut out, off, n)
	n1 := curve(r[1][0], r[1][1], h, level - 1, a, mut out, off + 2 * n)
	n2 := curve(r[2][0], r[2][1], h, level - 1, a, mut out, off + 2 * (n + n1))
	n3 := curve(r[3][0], r[3][1], h, level - 1, a - 1, mut out, off + 2 * (n + n1 + n2))
	reverse_points(mut out, off + 2 * (n + n1 + n2), n3)
	return n + n1 + n2 + n3
}
@[export: 'hilbert_curve']
pub fn hilbert_curve(v &i64, n usize, out &u8, cap usize) i64 {
	if n != 2 { return -1 }
	if v[0] < 1 || v[0] > 6 || v[1] < 0 || v[1] > 3 { return -1 }
	level := int(v[0]); points := 1 << (2 * level); bytes := points * 16
	if cap < bytes { return -2 }
	mut coords := []i64{len: 8192}
	curve(0, 0, i64(1) << (level + 1), level, int(v[1]), mut coords, 0)
	for i in 0 .. points * 2 {
		bits := u64(coords[i])
		for k in 0 .. 8 { unsafe { out[i * 8 + k] = u8(bits >> (8 * k)) } }
	}
	return i64(bytes)
}
