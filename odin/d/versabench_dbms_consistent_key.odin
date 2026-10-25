package versabench_dbms_consistent_key
import "core:c"

@(export, link_name="versabench_dbms_consistent_key")
versabench_dbms_consistent_key :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length < 1 || length > 17 || length != 16 do return -1
	for box := 0; box < 2; box += 1 {
		base := box * 8
		for d := 0; d < 4; d += 1 {
			lower := values[base+d]; upper := values[base+4+d]
			if lower < -8 || lower > 8 || upper < -8 || upper > 8 || lower > upper do return -1
		}
	}
	for d := 0; d < 4; d += 1 { if values[d] > values[12+d] || values[8+d] > values[4+d] do return 0 }
	return 1
}
