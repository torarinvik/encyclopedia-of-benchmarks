module max_jobs_before_deadlines

const max_jobs = 12

struct Job {
	deadline i64
	duration i64
	id int
}

fn before(left_duration i64, left_id int, right_duration i64, right_id int) bool {
	return left_duration < right_duration || (left_duration == right_duration && left_id < right_id)
}

fn heap_push(mut durations [max_jobs]i64, mut ids [max_jobs]int, mut size int,
	duration i64, id int) {
	mut index := size
	size++
	for index > 0 {
		parent := (index - 1) / 2
		if !before(duration, id, durations[parent], ids[parent]) { break }
		durations[index] = durations[parent]
		ids[index] = ids[parent]
		index = parent
	}
	durations[index] = duration
	ids[index] = id
}

fn heap_pop(mut durations [max_jobs]i64, mut ids [max_jobs]int, mut size int) (i64, int) {
	result := durations[0], ids[0]
	size--
	if size == 0 { return result }
	last_duration := durations[size]
	last_id := ids[size]
	mut index := 0
	for 2 * index + 1 < size {
		mut child := 2 * index + 1
		if child + 1 < size && before(durations[child + 1], ids[child + 1], durations[child], ids[child]) {
			child++
		}
		if !before(durations[child], ids[child], last_duration, last_id) { break }
		durations[index] = durations[child]
		ids[index] = ids[child]
		index = child
	}
	durations[index] = last_duration
	ids[index] = last_id
	return result
}

@[export: 'max_jobs_before_deadlines']
pub fn max_jobs_before_deadlines(input &i64, length usize) i64 {
	if length < 1 || length > 25 { return -1 }
	unsafe {
		count_value := input[0]
		if count_value < 0 || count_value > max_jobs || length != usize(1 + 2 * count_value) { return -1 }
		count := int(count_value)
		mut jobs := [max_jobs]Job{}
		for i in 0 .. count {
			deadline := input[1 + 2 * i]
			duration := input[2 + 2 * i]
			if deadline < 0 || deadline > 1000 || duration < 1 || duration > 1000 { return -1 }
			jobs[i] = Job{deadline, duration, i}
		}
		for i := 1; i < count; i++ {
			item := jobs[i]
			mut position := i
			for position > 0 && jobs[position - 1].deadline > item.deadline {
				jobs[position] = jobs[position - 1]
				position--
			}
			jobs[position] = item
		}
		mut heap_durations := [max_jobs]i64{}
		mut heap_ids := [max_jobs]int{}
		mut heap_size := 0
		mut completed := i64(0)
		mut end := count
		for end > 0 {
			end--
			heap_push(mut heap_durations, mut heap_ids, mut heap_size, jobs[end].duration, jobs[end].id)
			lower := if end == 0 { i64(0) } else { jobs[end - 1].deadline }
			mut interval := jobs[end].deadline - lower
			for interval > 0 && heap_size > 0 {
				remaining, id := heap_pop(mut heap_durations, mut heap_ids, mut heap_size)
				if remaining <= interval {
					interval -= remaining
					completed++
				} else {
					heap_push(mut heap_durations, mut heap_ids, mut heap_size, remaining - interval, id)
					interval = 0
				}
			}
		}
		return completed
	}
}
