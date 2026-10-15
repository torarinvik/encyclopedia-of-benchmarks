@[export: 'digital_root']
fn digital_root(n i64) i64 {
	if n < 0 { return -1 }
	mut value := n
	for value >= 10 {
		mut digits := value
		mut total := i64(0)
		for digits > 0 {
			total += digits % 10
			digits /= 10
		}
		value = total
	}
	return value
}
