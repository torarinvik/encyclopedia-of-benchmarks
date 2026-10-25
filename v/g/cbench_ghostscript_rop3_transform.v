// Independent ROP3 truth-table transforms; complete AFPL v5 is bundled.
@[export: 'cbench_ghostscript_rop3_transform']
pub fn cbench_ghostscript_rop3_transform(values &i64, length usize) i64 {
	if length > 3 || (length > 0 && values == nil) || length != 2 { return -1 }
	unsafe {
		if values[0] < 0 || values[0] > 14 || values[1] < 0 || values[1] > 255 { return -1 }
		mode := int(values[0]); code := u64(values[1])
		mut result := u64(0)
		for index in 0 .. 8 {
			d := index & 1; s := (index >> 1) & 1; t := (index >> 2) & 1
			mut source_index := index
			mut forced := -1
			if mode <= 2 { source_index ^= 1 << mode }
			else if mode <= 8 { dimension := (mode-3)/2; pinned := (mode-3)&1; source_index = (index & ~(1 << dimension)) | (pinned << dimension) }
			else if mode == 9 { source_index = (index & ~6) | (s << 2) | (t << 1) }
			else if mode <= 13 { operand := if mode < 12 { s } else { t }; if operand == ((mode-10)&1) { forced = d } }
			else { forced = 1 - int((code >> u32(index)) & 1) }
			bit := if forced < 0 { int((code >> u32(source_index)) & 1) } else { forced }
			result |= u64(bit) << u32(index)
		}
		return i64(result)
	}
}
