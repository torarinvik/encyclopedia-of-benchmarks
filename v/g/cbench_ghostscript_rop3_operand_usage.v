// Independent ROP3 truth-table dependency profile; full AFPL v5 is bundled.
@[export: 'cbench_ghostscript_rop3_operand_usage']
pub fn cbench_ghostscript_rop3_operand_usage(values &i64, length usize) i64 {
	if length > 2 || (length > 0 && values == nil) || length != 1 { return -1 }
	unsafe {
		if values[0] < 0 || values[0] > 255 { return -1 }
		code := u64(values[0])
		mut usage := u64(0)
		for dimension in 0 .. 3 {
			toggle := u64(1) << u32(dimension)
			for index in 0 .. 8 {
				if (u64(index) & toggle) == 0 && ((code >> u32(index)) & 1) != ((code >> u32(u64(index) | toggle)) & 1) {
					usage |= toggle
					break
				}
			}
		}
		return i64(usage)
	}
}
