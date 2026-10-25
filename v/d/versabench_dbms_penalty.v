module versabench_dbms_penalty

@[export: 'versabench_dbms_penalty']
pub fn versabench_dbms_penalty(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 1 || length > 17 || length != 16 { return -1 }
		for box in 0 .. 2 {
			for d in 0 .. 4 {
				lo := input[box*8+d]; hi := input[box*8+4+d]
				if lo < -8 || lo > 8 || hi < -8 || hi > 8 || lo >= hi { return -1 }
			}
		}
		mut joined := i64(1); mut original := i64(1)
		for d in 0 .. 4 {
			lo := if input[d] < input[8+d] { input[d] } else { input[8+d] }
			hi := if input[4+d] > input[12+d] { input[4+d] } else { input[12+d] }
			joined *= hi - lo
			original *= input[4+d] - input[d]
		}
		return joined - original
	}
}
