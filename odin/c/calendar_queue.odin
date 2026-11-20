package calendar_queue

import "core:c"

MAX_OPS :: 128
MAX_LIVE :: 64
MAX_BUCKETS :: 64
MAX_PRIORITY :: i64(1_000_000)
MAX_INPUT :: 1 + 2 * MAX_OPS + 1

Event :: struct { priority: i64, id: i64, next: int, active: bool }
Calendar :: struct {
	events: [MAX_LIVE]Event,
	heads: [MAX_BUCKETS]int,
	bucket_count: int,
	live: int,
	next_id: i64,
	last_priority: i64,
	last_bucket: int,
	width_num: i64,
	width_den: i64,
	top_num: i64,
	top_den: i64,
}

less :: proc "contextless" (a, b: Event) -> bool {
	return a.priority < b.priority || (a.priority == b.priority && a.id < b.id)
}

gcd :: proc "contextless" (a0, b0: i64) -> i64 {
	a, b := a0, b0
	for b != 0 { r := a % b; a = b; b = r }
	return a
}

virtual_bucket :: proc "contextless" (q: ^Calendar, priority: i64) -> int {
	return int((priority * q.width_den) / q.width_num)
}

reset_cursor :: proc "contextless" (q: ^Calendar, priority: i64) {
	virtual_index := virtual_bucket(q, priority)
	q.last_bucket = virtual_index % q.bucket_count
	q.top_num = (2 * i64(virtual_index) + 3) * q.width_num
	q.top_den = 2 * q.width_den
}

insert_event :: proc "contextless" (q: ^Calendar, slot: int) {
	bucket := virtual_bucket(q, q.events[slot].priority) % q.bucket_count
	previous, current := MAX_LIVE, q.heads[bucket]
	for current != MAX_LIVE && less(q.events[current], q.events[slot]) {
		previous = current
		current = q.events[current].next
	}
	q.events[slot].next = current
	if previous == MAX_LIVE { q.heads[bucket] = slot } else { q.events[previous].next = slot }
}

new_width :: proc "contextless" (q: ^Calendar) -> (i64, i64) {
	ordered: [MAX_LIVE]Event
	count := 0
	for event in q.events {
		if !event.active do continue
		at := count
		for at > 0 && less(event, ordered[at-1]) { ordered[at] = ordered[at-1]; at -= 1 }
		ordered[at] = event
		count += 1
	}
	if count < 2 do return 1, 1
	samples := count
	if count > 5 { samples = 5 + count/10; if samples > 25 { samples = 25 } }
	gaps := samples-1
	sum: i64 = 0
	for i := 0; i < gaps; i += 1 { sum += ordered[i+1].priority-ordered[i].priority }
	if sum == 0 do return 1, 1
	kept_sum: i64 = 0
	kept: i64 = 0
	for i := 0; i < gaps; i += 1 {
		gap := ordered[i+1].priority-ordered[i].priority
		if gap*i64(gaps) <= 2*sum { kept_sum += gap; kept += 1 }
	}
	if kept_sum == 0 || kept == 0 do return 1, 1
	numerator := 3*kept_sum
	divisor := gcd(numerator, kept)
	return numerator/divisor, kept/divisor
}

resize :: proc "contextless" (q: ^Calendar, buckets: int) {
	num, den := new_width(q)
	q.bucket_count = buckets
	q.width_num, q.width_den = num, den
	for i := 0; i < MAX_BUCKETS; i += 1 { q.heads[i] = MAX_LIVE }
	reset_cursor(q, q.last_priority)
	for i := 0; i < MAX_LIVE; i += 1 { if q.events[i].active { insert_event(q, i) } }
}

enqueue :: proc "contextless" (q: ^Calendar, priority: i64) -> bool {
	if priority < 0 || priority > MAX_PRIORITY || priority < q.last_priority || q.live == MAX_LIVE do return false
	slot := MAX_LIVE
	for i := 0; i < MAX_LIVE; i += 1 { if !q.events[i].active { slot = i; break } }
	if slot == MAX_LIVE do return false
	q.events[slot] = Event{priority, q.next_id, MAX_LIVE, true}
	q.next_id += 1
	q.live += 1
	insert_event(q, slot)
	if q.live > 2*q.bucket_count { resize(q, 2*q.bucket_count) }
	return true
}

dequeue :: proc "contextless" (q: ^Calendar, result: ^Event) -> bool {
	if q.live == 0 do return false
	bucket := q.last_bucket
	for {
		slot := q.heads[bucket]
		if slot != MAX_LIVE && q.events[slot].priority*q.top_den < q.top_num {
			result^ = q.events[slot]
			q.heads[bucket] = result.next
			q.events[slot].active = false
			q.live -= 1
			q.last_bucket = bucket
			q.last_priority = result.priority
			if q.bucket_count > 2 && i64(q.live) < i64(q.bucket_count/2-2) { resize(q, q.bucket_count/2) }
			return true
		}
		bucket = (bucket+1)%q.bucket_count
		q.top_num += 2*q.width_num
		if bucket == q.last_bucket {
			minimum := MAX_LIVE
			for i := 0; i < q.bucket_count; i += 1 {
				head := q.heads[i]
				if head != MAX_LIVE && (minimum == MAX_LIVE || less(q.events[head], q.events[minimum])) { minimum = head }
			}
			if minimum == MAX_LIVE do return false
			q.last_priority = q.events[minimum].priority
			reset_cursor(q, q.last_priority)
			bucket = q.last_bucket
		}
	}
}

put_i64 :: proc "contextless" (output: [^]u8, word: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[word*8+byte] = u8(bits >> (8*byte)) }
}

@(export)
calendar_queue :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 1 || length > MAX_INPUT do return -1
	count := input[0]
	if count < 0 || count > MAX_OPS || length != c.size_t(1+2*count) do return -1
	q := Calendar{bucket_count = 2, width_num = 1, width_den = 1, top_num = 3, top_den = 2}
	for i := 0; i < MAX_BUCKETS; i += 1 { q.heads[i] = MAX_LIVE }
	trace: [2*MAX_OPS]i64
	dequeued := 0
	for step := i64(0); step < count; step += 1 {
		opcode, argument := input[1+2*int(step)], input[2+2*int(step)]
		if opcode == 1 {
			if !enqueue(&q, argument) do return -1
		} else if opcode == 2 {
			if argument != 0 do return -1
			event: Event
			if !dequeue(&q, &event) do return -1
			trace[2*dequeued], trace[2*dequeued+1] = event.id, event.priority
			dequeued += 1
		} else { return -1 }
	}
	bytes := (1+2*dequeued)*8
	if output == nil || capacity < c.size_t(bytes) do return -2
	put_i64(output, 0, i64(dequeued))
	for word := 0; word < 2*dequeued; word += 1 { put_i64(output, word+1, trace[word]) }
	return i64(bytes)
}
