package versabench_dbms_penalty
import "core:c"

@(export, link_name="versabench_dbms_penalty")
versabench_dbms_penalty :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length < 1 || length > 17 || length != 16 do return -1
	for box := 0; box < 2; box += 1 {
		for d := 0; d < 4; d += 1 {
			lo := values[box*8+d]; hi := values[box*8+4+d]
			if lo < -8 || lo > 8 || hi < -8 || hi > 8 || lo >= hi do return -1
		}
	}
	joined: i64 = 1
	original: i64 = 1
	for d := 0; d < 4; d += 1 {
		lo := values[d]; if values[8+d] < lo do lo = values[8+d]
		hi := values[4+d]; if values[12+d] > hi do hi = values[12+d]
		joined *= hi-lo
		original *= values[4+d]-values[d]
	}
	return joined-original
}
