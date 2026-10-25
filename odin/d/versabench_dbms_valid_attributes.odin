package versabench_dbms_valid_attributes
import "core:c"

key_float_bits_valid :: proc "contextless" (payload: i64) -> i64 {
	if payload < 0 || payload > 0xffff_ffff do return -1
	bits := u32(payload)
	exponent := (bits >> 23) & 0xff
	fraction := bits & 0x7f_ffff
	if exponent == 0xff && fraction == 0 do return 0
	return 1
}

@(export, link_name="versabench_dbms_valid_attributes")
versabench_dbms_valid_attributes :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length < 1 || length > 104 do return -1
	raw_count := values[0]
	if raw_count < 0 || raw_count > 51 || length != c.size_t(1+2*int(raw_count)) do return -1
	for i := 0; i < int(raw_count); i += 1 {
		code := values[1+2*i]; payload := values[2+2*i]
		if code < 0 || code > 50 do return 0
		if code < 8 {
			valid := key_float_bits_valid(payload)
			if valid < 0 do return -1
			if valid == 0 do return 0
		} else {
			if payload != 0 && payload != 1 do return -1
			if payload == 0 do return 0
		}
	}
	return 1
}
