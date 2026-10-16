module queue_using_array

const max_q = 512
const max_input = 1025
const checksum_offset = i64(128)

@[export: 'queue_using_array']
pub fn queue_using_array(packed &i64, length usize) i64 {
	if unsafe { packed == nil } || length < 1 || length > max_input { return -1 }
	qv := unsafe { packed[0] }
	if qv < 0 || qv > max_q || length != usize(1 + qv * 2) { return -1 }
	q := int(qv)
	for i in 0 .. q {
		op := unsafe { packed[1 + i * 2] }
		value := unsafe { packed[2 + i * 2] }
		if op == 0 {
			if value < -128 || value > 127 { return -1 }
		} else if op == 1 {
			if value != 0 { return -1 }
		} else { return -1 }
	}
	mut values := []i16{len: 10}
	mut front := -1
	mut rear := -1
	mut checksum := i64(0)
	mut ordinal := i64(0)
	for i in 0 .. q {
		op := unsafe { packed[1 + i * 2] }
		value := unsafe { packed[2 + i * 2] }
		if op == 0 {
			if rear == 9 { continue }
			if front == -1 && rear == -1 { front = 0; rear = 0; values[0] = i16(value) }
			else if rear < 10 { rear++; values[rear] = i16(value) }
		} else {
			mut dequeued := i64(0)
			if front != -1 {
				if front == rear { dequeued = i64(values[front]); front = -1; rear = -1 }
				else { dequeued = i64(values[front]); front++ }
			}
			ordinal++
			checksum += ordinal * (dequeued + checksum_offset)
		}
	}
	return checksum
}
