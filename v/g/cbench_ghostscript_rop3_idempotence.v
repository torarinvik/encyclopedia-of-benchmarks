// Independent bounded profile; full Aladdin Free Public License v5 is bundled.
@[export: 'cbench_ghostscript_rop3_idempotence']
pub fn cbench_ghostscript_rop3_idempotence(values &i64, length usize) i64 {
	if length > 2 || (length > 0 && values == nil) || length != 1 { return -1 }
	unsafe {
		if values[0] < 0 || values[0] > 255 { return -1 }
		code := u64(values[0])
		for bit in 1 .. 8 {
			if bit % 2 == 1 && ((code >> u32(bit)) & 1) != 0 && ((code >> u32(bit-1)) & 1) == 0 { return 0 }
		}
		return 1
	}
}
