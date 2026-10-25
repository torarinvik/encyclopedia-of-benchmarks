// Independent bounded ROP3 profile; full AFPL v5 terms are in package LICENSE.txt.
@[export: 'cbench_ghostscript_rop3']
pub fn cbench_ghostscript_rop3(values &i64, length usize) i64 {
	if length > 5 || (length > 0 && values == nil) || length != 4 { return -1 }
	unsafe {
		for i in 0 .. 3 { if values[i] < 0 || values[i] > 4294967295 { return -1 } }
		if values[3] < 0 || values[3] > 255 { return -1 }
		d := u64(values[0]); s := u64(values[1]); t := u64(values[2]); code := u64(values[3])
		mut result := u64(0)
		for bit in 0 .. 32 {
			index := (((t >> u32(bit)) & 1) << 2) | (((s >> u32(bit)) & 1) << 1) | ((d >> u32(bit)) & 1)
			if ((code >> u32(index)) & 1) != 0 { result |= u64(1) << u32(bit) }
		}
		return i64(result)
	}
}
