module versabench_dbms_valid_attributes

fn key_float_bits_valid(payload i64) i64 {
	if payload < 0 || payload > 0xffff_ffff { return -1 }
	bits := u32(payload)
	exponent := (bits >> 23) & u32(0xff)
	fraction := bits & u32(0x7f_ffff)
	if exponent == u32(0xff) && fraction == 0 { return 0 }
	return 1
}

@[export: 'versabench_dbms_valid_attributes']
pub fn versabench_dbms_valid_attributes(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 1 || length > 104 { return -1 }
		raw_count := input[0]
		if raw_count < 0 || raw_count > 51 || length != usize(1 + 2 * int(raw_count)) { return -1 }
		for i in 0 .. int(raw_count) {
			code := input[1+2*i]; payload := input[2+2*i]
			if code < 0 || code > 50 { return 0 }
			if code < 8 {
				valid := key_float_bits_valid(payload)
				if valid < 0 { return -1 }
				if valid == 0 { return 0 }
			} else {
				if payload != 0 && payload != 1 { return -1 }
				if payload == 0 { return 0 }
			}
		}
		return 1
	}
}
