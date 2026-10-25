package versabench_dbms_valid_index_key
import "core:c"

binary32_ge :: proc "contextless" (a, b: u32) -> bool {
	exp_a := (a >> 23) & 0xff; frac_a := a & 0x7f_ffff
	exp_b := (b >> 23) & 0xff; frac_b := b & 0x7f_ffff
	if (exp_a == 0xff && frac_a != 0) || (exp_b == 0xff && frac_b != 0) do return false
	mag_a := a & 0x7fff_ffff; mag_b := b & 0x7fff_ffff
	if mag_a == 0 && mag_b == 0 do return true
	neg_a := (a >> 31) != 0; neg_b := (b >> 31) != 0
	if neg_a != neg_b do return !neg_a
	if neg_a do return mag_a <= mag_b
	return mag_a >= mag_b
}

@(export, link_name="versabench_dbms_valid_index_key")
versabench_dbms_valid_index_key :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length < 1 || length > 9 || length != 8 do return -1
	bits: [8]u32
	for i := 0; i < 8; i += 1 {
		if values[i] < 0 || values[i] > 0xffff_ffff do return -1
		bits[i] = u32(values[i])
	}
	for d := 0; d < 4; d += 1 { if binary32_ge(bits[d], bits[4+d]) do return 0 }
	return 1
}
