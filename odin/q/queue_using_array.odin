package queue_using_array

import "core:c"

MAX_Q :: 512
MAX_INPUT :: 1025
CHECKSUM_OFFSET :: i64(128)

@(export)
queue_using_array :: proc "c" (packed: [^]i64, length: c.size_t) -> i64 {
	if packed == nil || length < 1 || length > MAX_INPUT do return -1
	qv := packed[0]
	if qv < 0 || qv > MAX_Q || length != c.size_t(1 + qv * 2) do return -1
	q := int(qv)
	for i in 0..<q {
		op, value := packed[1 + i * 2], packed[2 + i * 2]
		if op == 0 { if value < -128 || value > 127 do return -1 }
		else if op == 1 { if value != 0 do return -1 }
		else do return -1
	}
	values: [10]i16
	front, rear := -1, -1
	checksum, ordinal := i64(0), i64(0)
	for i in 0..<q {
		op, value := packed[1 + i * 2], packed[2 + i * 2]
		if op == 0 {
			if rear == 9 do continue
			if front == -1 && rear == -1 { front, rear = 0, 0; values[0] = i16(value) }
			else if rear < 10 { rear += 1; values[rear] = i16(value) }
		} else {
			dequeued := i64(0)
			if front != -1 {
				if front == rear { dequeued = i64(values[front]); front, rear = -1, -1 }
				else { dequeued = i64(values[front]); front += 1 }
			}
			ordinal += 1
			checksum += ordinal * (dequeued + CHECKSUM_OFFSET)
		}
	}
	return checksum
}
