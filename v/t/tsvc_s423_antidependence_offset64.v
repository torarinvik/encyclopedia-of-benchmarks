module tsvc_s423_antidependence_offset64

@[export: 'tsvc_s423_antidependence_offset64']
pub fn tsvc_s423_antidependence_offset64(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 130 || length > 193 { return -1 }
	unsafe {
		if input[0] < 65 || input[0] > 128 { return -1 }
		n := int(input[0])
		if length != usize(n+65) { return -1 }
		mut a := []i64{len: 128, init: 0}
		mut x := []i64{len: 192, init: 0}
		for i in 0 .. n {
			a[i] = input[1+i]
			if a[i] < 0 || a[i] > 2 { return -1 }
		}
		for i in 0 .. 64 {
			x[i] = input[1+n+i]
			if x[i] < 0 || x[i] > 2 { return -1 }
		}
		for i in 64 .. n+64 { x[i] = 1 }
		for i in 0 .. n-1 { x[i+1] = x[i+64] + a[i] }
		mut total := i64(0)
		for i in 0 .. n { total += x[i] }
		return total
	}
}
