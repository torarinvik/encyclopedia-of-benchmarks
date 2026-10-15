module demonetization

const max_amount = i64(30)
const max_denominations = i64(4)

fn ways(amount i64, input &i64, count i64) i64 {
	if amount < 0 || count < 0 { return 0 }
	if amount == 0 { return 1 }
	if count == 0 { return 0 }
	denomination := unsafe { input[count + 1] }
	return ways(amount, input, count - 1) + ways(amount - denomination, input, count)
}

// Count denomination combinations with the source's recursive recurrence.
@[export: 'demonetization']
pub fn demonetization(input &i64, length usize) i64 {
	if length < 2 || length > 6 { return -1 }
	amount := unsafe { input[0] }
	count := unsafe { input[1] }
	if amount < -max_amount || amount > max_amount || count < 0 || count > max_denominations
		|| length != usize(count + 2) { return -1 }
	for index in 0 .. int(count) {
		denomination := unsafe { input[index + 2] }
		if denomination < 1 || denomination > max_amount { return -1 }
	}
	return ways(amount, input, count)
}
