package main

import "core:c"

// Independent ROP3 truth-table dependency profile; full AFPL v5 is bundled.
@(export)
cbench_ghostscript_rop3_operand_usage :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if length > 2 || (length > 0 && values == nil) || length != 1 do return -1
	if values[0] < 0 || values[0] > 255 do return -1
	code := u64(values[0])
	usage: u64 = 0
	for dimension := u64(0); dimension < 3; dimension += 1 {
		toggle := u64(1) << dimension
		for index := u64(0); index < 8; index += 1 {
			if (index & toggle) == 0 && ((code >> index) & 1) != ((code >> (index | toggle)) & 1) {
				usage |= toggle
				break
			}
		}
	}
	return i64(usage)
}
