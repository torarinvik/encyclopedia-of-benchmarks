module lcfs_hashing

const max_capacity = 32
const max_input_length = 35
const max_key = i64(1_000_000)

@[export: 'lcfs_hashing']
pub fn lcfs_hashing(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > max_input_length { return -1 }
		capacity_value := input[0]
		count_value := input[1]
		if capacity_value < 1 || capacity_value > max_capacity || count_value < 0 || count_value > capacity_value { return -1 }
		if length != usize(count_value + 2) { return -1 }
		capacity := int(capacity_value)
		count := int(count_value)
		for i in 0 .. count {
			key := input[i + 2]
			if key < 0 || key > max_key { return -1 }
			for j in 0 .. i {
				if input[j + 2] == key { return -1 }
			}
		}

		mut table := [32]i64{}
		for i in 0 .. capacity { table[i] = -1 }
		mut displacements := i64(0)
		for i in 0 .. count {
			mut incoming := input[i + 2]
			mut slot := int(incoming % capacity_value)
			mut probes := 0
			for table[slot] != -1 {
				if probes >= capacity { return -1 }
				resident := table[slot]
				table[slot] = incoming
				incoming = resident
				slot = (slot + 1) % capacity
				probes++
				displacements++
			}
			table[slot] = incoming
		}
		return displacements
	}
}
