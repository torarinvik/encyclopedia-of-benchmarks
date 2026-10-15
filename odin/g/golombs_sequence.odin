package main

@(export, link_name="golombs_sequence")
golombs_sequence :: proc(index: i64) -> i64 {
	if index < 0 || index > 64 do return -1
	if index == 0 do return 1
	if index <= 2 do return 2
	queue: [65]i64 = {}
	queue[0] = 2
	head: int = 0
	tail: int = 1
	generated: i64 = 3
	value: i64 = 3
	for generated <= index {
		repetitions := queue[head]
		head += 1
		for repeated: i64 = 0; repeated < repetitions && generated <= index; repeated += 1 {
			queue[tail] = value
			tail += 1
			if generated == index do return value
			generated += 1
		}
		value += 1
	}
	return -1
}

main :: proc() {}
