package digital_root

@(export)
digital_root :: proc "contextless" (n: i64) -> i64 {
	if n < 0 do return -1
	value := n
	for value >= 10 {
		digits := value
		total := i64(0)
		for digits > 0 {
			total += digits % 10
			digits /= 10
		}
		value = total
	}
	return value
}
