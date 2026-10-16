module unbias_01

@[export: 'unbias_01']
pub fn unbias_01(input &i64, length usize) i64 {
	if length < 1 || length > 257 { return -1 }
	n := input[0]
	if n < 0 || n > 256 || length != usize(n + 1) { return -1 }
	for i in 0 .. int(n) { if input[i + 1] != 0 && input[i + 1] != 1 { return -1 } }
	mut i := 0
	for i + 1 < int(n) { if input[i + 1] != input[i + 2] { return input[i + 1] }; i += 2 }
	return -1
}
