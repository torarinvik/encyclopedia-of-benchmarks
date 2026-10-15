@[export: 'golombs_sequence']
pub fn golombs_sequence(index i64) i64 {
	if index < 0 || index > 64 { return -1 }
	if index == 0 { return 1 }
	if index <= 2 { return 2 }
	mut queue := [65]i64{}
	queue[0] = 2
	mut head := 0
	mut tail := 1
	mut generated := i64(3)
	mut value := i64(3)
	for generated <= index {
		repetitions := queue[head]
		head++
		mut repeated := i64(0)
		for repeated < repetitions && generated <= index {
			queue[tail] = value
			tail++
			if generated == index { return value }
			generated++
			repeated++
		}
		value++
	}
	return -1
}
