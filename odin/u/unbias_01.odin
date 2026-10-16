package unbias_01

@(export, link_name="unbias_01")
unbias_01 :: proc "c" (input: [^]i64, length: uint) -> i64 {
	if length < 1 || length > 257 do return -1
	n := input[0]
	if n < 0 || n > 256 || length != uint(n + 1) do return -1
	for i: i64 = 0; i < n; i += 1 { if input[i + 1] != 0 && input[i + 1] != 1 do return -1 }
	for i: i64 = 0; i + 1 < n; i += 2 { if input[i + 1] != input[i + 2] do return input[i + 1] }
	return -1
}

main :: proc() {}
