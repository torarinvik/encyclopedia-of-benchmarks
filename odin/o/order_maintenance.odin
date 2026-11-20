package order_maintenance

import "core:c"

MAX_ELEMENTS :: 64
MAX_OPERATIONS :: 128
MAX_INPUT_LENGTH :: c.size_t(387)
LABEL_MODULUS :: i64(2_147_483_648)
LABEL_RING :: i64(4_294_967_296)

label_width :: proc(left, right: i64) -> i64 {
	difference := right - left
	if difference < 0 do difference += LABEL_RING
	if difference == 0 do return LABEL_MODULUS
	if difference > LABEL_MODULUS do return difference - LABEL_MODULUS
	return difference
}

insert_after :: proc(anchor, new_id: int, labels: [^]i64,
	previous, following: [^]int) {
	successor := following[anchor]
	if label_width(labels[anchor], labels[successor]) <= 1 {
		middle := successor
		end := following[middle]
		required := i64(3)
		for end != anchor && label_width(labels[anchor], labels[end]) <=
			4 * label_width(labels[anchor], labels[middle]) {
			required += 1
			end = following[end]
			if end == anchor do break
			required += 1
			end = following[end]
			middle = following[middle]
		}
		interval := LABEL_MODULUS
		if end != anchor do interval = label_width(labels[anchor], labels[end])
		spacing := interval / required
		value := labels[end]
		cursor := end
		for {
			if cursor == 0 {
				value += LABEL_MODULUS
				if value >= LABEL_RING do value -= LABEL_RING
			}
			cursor = previous[cursor]
			if cursor == anchor do break
			value -= spacing
			if value < 0 do value += LABEL_RING
			labels[cursor] = value
		}
	}
	successor = following[anchor]
	labels[new_id] = labels[anchor] + label_width(labels[anchor], labels[successor]) / 2
	if labels[new_id] >= LABEL_RING do labels[new_id] -= LABEL_RING
	previous[new_id] = anchor
	following[new_id] = successor
	following[anchor] = new_id
	previous[successor] = new_id
}

@(export)
order_maintenance :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_INPUT_LENGTH do return -1
	capacity_value := input[0]
	operation_value := input[1]
	if capacity_value < 0 || capacity_value > MAX_ELEMENTS || operation_value < 0 ||
		operation_value > MAX_OPERATIONS || length != c.size_t(2 + 3 * operation_value) do return -1
	capacity := int(capacity_value)
	operation_count := int(operation_value)

	labels: [MAX_ELEMENTS + 1]i64
	previous: [MAX_ELEMENTS + 1]int
	following: [MAX_ELEMENTS + 1]int
	inserted := 0
	checksum := i64(0)
	for operation := 0; operation < operation_count; operation += 1 {
		offset := 2 + 3 * operation
		opcode := input[offset]
		first := input[offset + 1]
		second := input[offset + 2]
		if opcode == 0 {
			if inserted >= capacity || first < 0 || first > i64(inserted) || second != i64(inserted + 1) do return -1
			inserted += 1
			insert_after(int(first), inserted, &labels[0], &previous[0], &following[0])
		} else if opcode == 1 {
			if first < 1 || first > i64(inserted) || second < 1 || second > i64(inserted) do return -1
			if labels[int(first)] < labels[int(second)] do checksum += i64(operation + 1)
		} else {
			return -1
		}
	}
	return checksum
}
