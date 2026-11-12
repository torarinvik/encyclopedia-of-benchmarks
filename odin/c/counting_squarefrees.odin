package counting_squarefrees

Max_N :: i64(1_000_000_000_000)
Max_Root :: 1_000_000

integer_sqrt :: proc "contextless" (value: i64) -> i64 {
	low, high := i64(1), i64(Max_Root)
	for low < high {
		middle := low + (high-low+1)/2
		if middle <= value/middle { low = middle } else { high = middle-1 }
	}
	return low
}

@(export)
counting_squarefrees :: proc "c" (n: i64) -> i64 {
	if n < 1 || n > Max_N do return -1
	limit := int(integer_sqrt(n))
	mobius: [Max_Root+1]u8 = {}
	composite: [Max_Root+1]bool = {}
	for value := 1; value <= limit; value += 1 { mobius[value] = 1 }

	for prime := 2; prime <= limit; prime += 1 {
		if composite[prime] do continue
		if prime <= limit/prime {
			for multiple := prime*prime; multiple <= limit; multiple += prime { composite[multiple] = true }
		}
		for multiple := prime; multiple <= limit; multiple += prime {
			if mobius[multiple] == 1 { mobius[multiple] = 2 }
			else if mobius[multiple] == 2 { mobius[multiple] = 1 }
		}
		if prime <= limit/prime {
			square := prime*prime
			for multiple := square; multiple <= limit; multiple += square { mobius[multiple] = 0 }
		}
	}

	count: i64 = 0
	for divisor := 1; divisor <= limit; divisor += 1 {
		d := i64(divisor)
		quotient := n/(d*d)
		if mobius[divisor] == 1 { count += quotient }
		else if mobius[divisor] == 2 { count -= quotient }
	}
	return count
}
