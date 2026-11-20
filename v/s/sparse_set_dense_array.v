module sparse_set_dense_array

const max_universe = 32
const max_operations = 30
const max_length = 63

@[export: 'sparse_set_dense_array']
pub fn sparse_set_dense_array(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > max_length { return -1 }
		if input[0] < 1 || input[0] > max_universe || input[1] < 0 || input[1] > max_operations { return -1 }
		universe := int(input[0])
		count := int(input[1])
		if length != usize(2+2*count) { return -1 }
		for i in 0 .. count {
			opcode := input[2+2*i]
			key := input[3+2*i]
			if opcode < 0 || opcode > 3 || key < 0 || key >= input[0] { return -1 }
			if opcode == 3 && key != 0 { return -1 }
		}
		mut dense := [max_universe]i64{}
		mut sparse := [max_universe]int{}
		for key in 0 .. universe { sparse[key] = universe }
		mut size := 0
		mut answers := i64(0)
		for i in 0 .. count {
			opcode := int(input[2+2*i])
			key := int(input[3+2*i])
			index := sparse[key]
			present := index < size && dense[index] == i64(key)
			mut status := i64(0)
			if opcode == 0 {
				if !present {
					dense[size] = i64(key)
					sparse[key] = size
					size++
					status = 1
				}
			} else if opcode == 1 {
				if present {
					last := int(dense[size-1])
					dense[index] = dense[size-1]
					sparse[last] = index
					size--
					status = 1
				}
			} else if opcode == 2 {
				if present { status = 1 }
			} else {
				if size > 0 { status = 1 }
				size = 0
			}
			answers = (answers << 1) | status
		}
		mut final_mask := i64(0)
		for i in 0 .. size { final_mask |= i64(1) << int(dense[i]) }
		return (final_mask << count) | answers
	}
}
