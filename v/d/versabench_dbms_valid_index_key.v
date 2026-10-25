module versabench_dbms_valid_index_key

fn binary32_ge(a u32, b u32) bool {
	exp_a := (a >> 23) & u32(0xff); frac_a := a & u32(0x7f_ffff)
	exp_b := (b >> 23) & u32(0xff); frac_b := b & u32(0x7f_ffff)
	if (exp_a == u32(0xff) && frac_a != 0) || (exp_b == u32(0xff) && frac_b != 0) { return false }
	mag_a := a & u32(0x7fff_ffff); mag_b := b & u32(0x7fff_ffff)
	if mag_a == 0 && mag_b == 0 { return true }
	neg_a := (a >> 31) != 0; neg_b := (b >> 31) != 0
	if neg_a != neg_b { return !neg_a }
	if neg_a { return mag_a <= mag_b }
	return mag_a >= mag_b
}

@[export: 'versabench_dbms_valid_index_key']
pub fn versabench_dbms_valid_index_key(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 1 || length > 9 || length != 8 { return -1 }
		mut bits := [8]u32{}
		for i in 0 .. 8 {
			payload := input[i]
			if payload < 0 || payload > 0xffff_ffff { return -1 }
			bits[i] = u32(payload)
		}
		for d in 0 .. 4 { if binary32_ge(bits[d], bits[4+d]) { return 0 } }
		return 1
	}
}
