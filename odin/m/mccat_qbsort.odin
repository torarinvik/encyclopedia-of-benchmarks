package mccat_qbsort
import "core:c"

bubble :: proc(a: ^[32]i32, n: int) {
	if n < 2 do return
	for end := n; end > 1; end -= 1 {
		for i := 0; i + 1 < end; i += 1 { if a[i + 1] < a[i] { t := a[i]; a[i] = a[i + 1]; a[i + 1] = t } }
	}
}
quick :: proc(a: ^[32]i32, n: int) {
	if n < 2 do return
	pivot := a[0]; lower: [32]i32 = {}; upper: [32]i32 = {}; nl, nu := 0, 0
	for i := 1; i < n; i += 1 { if a[i] < pivot { lower[nl] = a[i]; nl += 1 } else { upper[nu] = a[i]; nu += 1 } }
	quick(&upper, nu); quick(&lower, nl); k := 0
	for i := 0; i < nl; i += 1 { a[k] = lower[i]; k += 1 }; a[k] = pivot; k += 1
	for i := 0; i < nu; i += 1 { a[k] = upper[i]; k += 1 }
}
@(export)
mccat_qbsort :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 3 || length > 34 do return -1
	mode, cv := input[0], input[1]
	if (mode != 0 && mode != 1) || cv < 1 || cv > 32 do return -1
	n := int(cv); if length != c.size_t(n + 2) do return -1
	values: [32]i32 = {}
	for i := 0; i < n; i += 1 { v := input[i + 2]; if v < -2147483648 || v > 2147483647 do return -1; values[i] = i32(v) }
	for pass := 0; pass < 1000; pass += 1 { for i := 0; i < n; i += 1 { values[i] = i32(input[i + 2]) }; if mode == 0 { bubble(&values, n) } else { quick(&values, n) } }
	need := 4 * n; if output == nil || capacity < c.size_t(need) do return -2
	for i := 0; i < n; i += 1 { bits := u32(values[i]); for b := 0; b < 4; b += 1 { output[i * 4 + b] = u8((bits >> (8 * b)) & 255) } }
	return i64(need)
}
