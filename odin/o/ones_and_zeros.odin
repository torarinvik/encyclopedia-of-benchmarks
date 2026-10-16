package ones_and_zeros

import "core:c"

@(export)
ones_and_zeros :: proc "c" (v: [^]i64, n: c.size_t) -> i64 {
	if v == nil || n < 3 || v[0] < 0 || v[0] > 32 || v[1] < 0 || v[1] > 32 || v[2] < 0 || v[2] > 32 || int(n) != 3+2*int(v[0]) do return -1
	dp: [33][33]i64
	for i := 0; i < int(v[0]); i += 1 {
		z, o := v[3+2*i], v[4+2*i]; if z < 0 || z > 32 || o < 0 || o > 32 do return -1
		for a := int(v[1]); a >= int(z); a -= 1 { for b := int(v[2]); b >= int(o); b -= 1 { candidate := dp[a-int(z)][b-int(o)] + 1; if candidate > dp[a][b] { dp[a][b] = candidate } } }
	}
	return dp[int(v[1])][int(v[2])]
}
