module next_palindromic_number

const max_input = i64(9999999999999999)

fn next_for(number i64) i64 {
	mut digits := [17]u8{}
	mut remaining := number
	mut count := 0
	for {
		digits[count] = u8(remaining % 10)
		count++
		remaining /= 10
		if remaining == 0 { break }
	}
	for left in 0 .. count / 2 {
		right := count - 1 - left
		swap := digits[left]
		digits[left] = digits[right]
		digits[right] = swap
	}
	for left in 0 .. count / 2 {
		digits[count - 1 - left] = digits[left]
	}
	mut candidate := i64(0)
	for i in 0 .. count { candidate = candidate * 10 + i64(digits[i]) }
	if candidate > number { return candidate }

	mut position := (count + 1) / 2
	for position > 0 && digits[position - 1] == 9 {
		digits[position - 1] = 0
		position--
	}
	if position == 0 {
		mut power := i64(1)
		for _ in 0 .. count { power *= 10 }
		return power + 1
	}
	digits[position - 1]++
	for left in 0 .. count / 2 {
		digits[count - 1 - left] = digits[left]
	}
	candidate = 0
	for i in 0 .. count { candidate = candidate * 10 + i64(digits[i]) }
	return candidate
}

@[export: 'next_palindromic_number']
pub fn next_palindromic_number(values &i64, length usize) i64 {
	if unsafe { values == nil } || length != 1 { return -1 }
	unsafe {
		number := values[0]
		if number < 0 || number > max_input { return -1 }
		return next_for(number)
	}
}
