module one_hot_encode

@[export: 'one_hot_encode']
pub fn one_hot_encode(values &i64, length usize, output &u8, capacity usize) i64 {
	if length < 2 || length > 33 { return -1 }
	rows_raw := unsafe { values[0] }
	if rows_raw < 1 || rows_raw > 32 || length != usize(rows_raw + 1) { return -1 }
	rows := int(rows_raw)
	mut present := [26]bool{}
	for i in 0 .. rows { x := unsafe { values[i+1] }; if x < 0 || x > 25 { return -1 }; present[int(x)] = true }
	mut map := [26]int{}
	mut cols := 0
	for i in 0 .. 26 { if present[i] { map[i] = cols; cols++ } }
	needed := rows * cols
	if usize(needed) > capacity || (needed > 0 && isnil(output)) { return -2 }
	for r in 0 .. rows { for c in 0 .. cols { if map[int(unsafe { values[r+1] })] == c { unsafe { output[r*cols+c] = 1 } } else { unsafe { output[r*cols+c] = 0 } } } }
	return i64(needed)
}
