package parenthesis

import "core:c"

@(export)
parenthesis :: proc "c" (v: [^]i64, n: c.size_t) -> i64 {
	if v == nil || n < 1 || n > 129 || v[0] < 0 || v[0] > 128 || n != c.size_t(v[0] + 1) do return -1
	balance := i64(0)
	for i := 1; i < int(n); i += 1 {
		x := v[i]; if x < 0 || x > 127 do return -1
		if x == 40 { balance += 1 } else if x == 41 { balance -= 1; if balance < 0 do return 0 }
	}
	return i64(balance == 0)
}
