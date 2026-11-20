module calendar_queue

const max_ops = 128
const max_live = 64
const max_buckets = 64
const max_priority = i64(1_000_000)
const max_input = 1 + 2 * max_ops + 1

struct Event {
	priority i64
	id       i64
	next     int = max_live
	active   bool
}

struct Calendar {
mut:
	events       [max_live]Event
	heads        [max_buckets]int
	bucket_count int = 2
	live         int
	next_id      i64
	last_priority i64
	last_bucket  int
	width_num    i64 = 1
	width_den    i64 = 1
	top_num      i64 = 3
	top_den      i64 = 2
}

fn less_event(a Event, b Event) bool {
	return a.priority < b.priority || (a.priority == b.priority && a.id < b.id)
}

fn gcd(a0 i64, b0 i64) i64 {
	mut a := a0
	mut b := b0
	for b != 0 { r := a % b; a = b; b = r }
	return a
}

fn virtual_bucket(q &Calendar, priority i64) int {
	return int((priority * q.width_den) / q.width_num)
}

fn reset_cursor(mut q Calendar, priority i64) {
	virtual_index := virtual_bucket(q, priority)
	q.last_bucket = virtual_index % q.bucket_count
	q.top_num = (2 * i64(virtual_index) + 3) * q.width_num
	q.top_den = 2 * q.width_den
}

fn insert_event(mut q Calendar, slot int) {
	bucket := virtual_bucket(q, q.events[slot].priority) % q.bucket_count
	mut previous := max_live
	mut current := q.heads[bucket]
	for current != max_live && less_event(q.events[current], q.events[slot]) {
		previous = current
		current = q.events[current].next
	}
	q.events[slot].next = current
	if previous == max_live { q.heads[bucket] = slot } else { q.events[previous].next = slot }
}

fn new_width(q &Calendar) (i64, i64) {
	mut ordered := [max_live]Event{}
	mut count := 0
	for event in q.events {
		if !event.active { continue }
		mut at := count
		for at > 0 && less_event(event, ordered[at - 1]) { ordered[at] = ordered[at - 1]; at-- }
		ordered[at] = event
		count++
	}
	if count < 2 { return 1, 1 }
	samples := if count <= 5 { count } else { min(25, 5 + count / 10) }
	gaps := samples - 1
	mut sum := i64(0)
	for i in 0 .. gaps { sum += ordered[i + 1].priority - ordered[i].priority }
	if sum == 0 { return 1, 1 }
	mut kept_sum := i64(0)
	mut kept := i64(0)
	for i in 0 .. gaps {
		gap := ordered[i + 1].priority - ordered[i].priority
		if gap * i64(gaps) <= 2 * sum { kept_sum += gap; kept++ }
	}
	if kept_sum == 0 || kept == 0 { return 1, 1 }
	numerator := 3 * kept_sum
	divisor := gcd(numerator, kept)
	return numerator / divisor, kept / divisor
}

fn resize(mut q Calendar, buckets int) {
	num, den := new_width(q)
	q.bucket_count = buckets
	q.width_num = num
	q.width_den = den
	for i in 0 .. max_buckets { q.heads[i] = max_live }
	reset_cursor(mut q, q.last_priority)
	for i in 0 .. max_live { if q.events[i].active { insert_event(mut q, i) } }
}

fn enqueue(mut q Calendar, priority i64) bool {
	if priority < 0 || priority > max_priority || priority < q.last_priority || q.live == max_live { return false }
	mut slot := max_live
	for i in 0 .. max_live { if !q.events[i].active { slot = i; break } }
	if slot == max_live { return false }
	q.events[slot] = Event{priority: priority, id: q.next_id, next: max_live, active: true}
	q.next_id++
	q.live++
	insert_event(mut q, slot)
	if q.live > 2 * q.bucket_count { resize(mut q, q.bucket_count * 2) }
	return true
}

fn dequeue(mut q Calendar) ?Event {
	if q.live == 0 { return none }
	mut bucket := q.last_bucket
	for {
		slot := q.heads[bucket]
		if slot != max_live && q.events[slot].priority * q.top_den < q.top_num {
			event := q.events[slot]
			q.heads[bucket] = event.next
			q.events[slot].active = false
			q.live--
			q.last_bucket = bucket
			q.last_priority = event.priority
			if q.bucket_count > 2 && i64(q.live) < i64(q.bucket_count / 2 - 2) { resize(mut q, q.bucket_count / 2) }
			return event
		}
		bucket = (bucket + 1) % q.bucket_count
		q.top_num += 2 * q.width_num
		if bucket == q.last_bucket {
			mut minimum := max_live
			for i in 0 .. q.bucket_count {
				head := q.heads[i]
				if head != max_live && (minimum == max_live || less_event(q.events[head], q.events[minimum])) { minimum = head }
			}
			if minimum == max_live { return none }
			q.last_priority = q.events[minimum].priority
			reset_cursor(mut q, q.last_priority)
			bucket = q.last_bucket
		}
	}
}

fn put_i64_le(mut output &u8, word int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 { unsafe { output[word * 8 + byte] = u8((bits >> (8 * byte)) & 255) } }
}

@[export: 'calendar_queue']
pub fn calendar_queue(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 1 || length > max_input { return -1 }
	unsafe {
		count := input[0]
		if count < 0 || count > max_ops || length != usize(1 + 2 * count) { return -1 }
		mut q := Calendar{}
		for i in 0 .. max_buckets { q.heads[i] = max_live }
		mut trace := [2 * max_ops]i64{}
		mut dequeued := 0
		for step in 0 .. int(count) {
			opcode := input[1 + 2 * step]
			argument := input[2 + 2 * step]
			if opcode == 1 {
				if !enqueue(mut q, argument) { return -1 }
			} else if opcode == 2 {
				if argument != 0 { return -1 }
				event := dequeue(mut q) or { return -1 }
				trace[2 * dequeued] = event.id
				trace[2 * dequeued + 1] = event.priority
				dequeued++
			} else { return -1 }
		}
		bytes := (1 + 2 * dequeued) * 8
		if unsafe { output == nil } || capacity < usize(bytes) { return -2 }
		put_i64_le(mut output, 0, i64(dequeued))
		for word in 0 .. 2 * dequeued { put_i64_le(mut output, word + 1, trace[word]) }
		return i64(bytes)
	}
}
