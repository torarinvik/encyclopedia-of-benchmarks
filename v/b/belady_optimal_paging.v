module belady_optimal_paging

const max_capacity = 8
const max_requests = 64
const page_count = 16
const max_input_length = usize(67)
const checksum_radix = i64(33281)

@[export: 'belady_optimal_paging']
pub fn belady_optimal_paging(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > max_input_length { return -1 }
		capacity_value := input[0]
		count_value := input[1]
		if capacity_value < 1 || capacity_value > max_capacity || count_value < 0 || count_value > max_requests {
			return -1
		}
		if length != usize(2 + count_value) { return -1 }
		capacity := int(capacity_value)
		count := int(count_value)
		mut requests := [max_requests]int{}
		for time in 0 .. count {
			page := input[2 + time]
			if page < 0 || page >= page_count { return -1 }
			requests[time] = int(page)
		}
		mut next_after := [max_requests * page_count]int{}
		mut next_position := [page_count]int{}
		for page in 0 .. page_count { next_position[page] = count }
		mut cursor := count
		for cursor > 0 {
			cursor--
			for page in 0 .. page_count { next_after[cursor * page_count + page] = next_position[page] }
			next_position[requests[cursor]] = cursor
		}

		mut resident := [page_count]bool{}
		mut resident_count := 0
		mut misses := i64(0)
		mut eviction_checksum := i64(0)
		for time in 0 .. count {
			requested := requests[time]
			if resident[requested] { continue }
			misses++
			if resident_count == capacity {
				mut victim := -1
				mut farthest := -1
				for page in 0 .. page_count {
					if !resident[page] { continue }
					following := next_after[time * page_count + page]
					if following > farthest { victim = page; farthest = following }
				}
				resident[victim] = false
				resident_count--
				eviction_checksum += i64((time + 1) * (victim + 1))
			}
			resident[requested] = true
			resident_count++
		}
		return misses * checksum_radix + eviction_checksum
	}
}
