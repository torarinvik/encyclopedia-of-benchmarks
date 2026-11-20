module order_maintenance

const max_elements = 64
const max_operations = 128
const max_input_length = usize(387)
const label_modulus = i64(2_147_483_648)
const label_ring = i64(4_294_967_296)

fn label_width(left i64, right i64) i64 {
	mut difference := right - left
	if difference < 0 { difference += label_ring }
	if difference == 0 { return label_modulus }
	if difference > label_modulus { return difference - label_modulus }
	return difference
}

@[export: 'order_maintenance']
pub fn order_maintenance(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > max_input_length { return -1 }
		capacity_value := input[0]
		operation_value := input[1]
		if capacity_value < 0 || capacity_value > max_elements ||
			operation_value < 0 || operation_value > max_operations { return -1 }
		capacity := int(capacity_value)
		operation_count := int(operation_value)
		if length != usize(2 + 3 * operation_count) { return -1 }

		mut labels := [65]i64{}
		mut previous := [65]int{}
		mut following := [65]int{}
		mut inserted := 0
		mut checksum := i64(0)
		for operation in 0 .. operation_count {
			offset := 2 + 3 * operation
			opcode := input[offset]
			first := input[offset + 1]
			second := input[offset + 2]
			if opcode == 0 {
				if inserted >= capacity || first < 0 || first > i64(inserted) ||
					second != i64(inserted + 1) { return -1 }
				inserted++
				anchor := int(first)
				new_id := inserted
				successor := following[anchor]
				if label_width(labels[anchor], labels[successor]) <= 1 {
					mut middle := successor
					mut ending := following[middle]
					mut required := i64(3)
					for ending != anchor && label_width(labels[anchor], labels[ending]) <=
						4 * label_width(labels[anchor], labels[middle]) {
						required++
						ending = following[ending]
						if ending == anchor { break }
						required++
						ending = following[ending]
						middle = following[middle]
					}
					interval := label_modulus
					if ending != anchor { interval = label_width(labels[anchor], labels[ending]) }
					spacing := interval / required
					mut value := labels[ending]
					mut cursor := ending
					for {
						if cursor == 0 {
							value += label_modulus
							if value >= label_ring { value -= label_ring }
						}
						cursor = previous[cursor]
						if cursor == anchor { break }
						value -= spacing
						if value < 0 { value += label_ring }
						labels[cursor] = value
					}
				}
				successor = following[anchor]
				labels[new_id] = labels[anchor] + label_width(labels[anchor], labels[successor]) / 2
				if labels[new_id] >= label_ring { labels[new_id] -= label_ring }
				previous[new_id] = anchor
				following[new_id] = successor
				following[anchor] = new_id
				previous[successor] = new_id
			} else if opcode == 1 {
				if first < 1 || first > i64(inserted) || second < 1 || second > i64(inserted) { return -1 }
				if labels[int(first)] < labels[int(second)] { checksum += i64(operation + 1) }
			} else { return -1 }
		}
		return checksum
	}
}
