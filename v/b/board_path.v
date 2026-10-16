module board_path

@[export: 'board_path']
pub fn board_path(input &i64, length usize) i64 {
	if input == nil || length != 2 { return -1 }
	unsafe {
		start := input[0]
		end := input[1]
		if start < 0 || end < 0 || start > 30 || end > 30 || start > end { return -1 }
		mut ways := []i64{len: 31}
		ways[int(end)] = 1
		if end > start {
			for i := int(end) - 1; i >= int(start); i-- {
				for die in 1 .. 7 { if i + die <= int(end) { ways[i] += ways[i + die] } }
			}
		}
		return ways[int(start)]
	}
}
