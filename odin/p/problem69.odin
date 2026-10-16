package problem69

Max_Limit :: 1_000_000

@(export)
problem69 :: proc "c" (inclusive_limit: i64) -> i64 {
	if inclusive_limit < 1 || inclusive_limit > Max_Limit do return -1
	limit := int(inclusive_limit)
	phi := make([]u32, limit + 1)
	defer delete(phi)
	for value := 0; value <= limit; value += 1 { phi[value] = u32(value) }
	for number := 2; number <= limit; number += 1 {
		if phi[number] != u32(number) do continue
		phi[number] -= 1
		for multiple := number * 2; multiple <= limit; multiple += number {
			phi[multiple] = (phi[multiple] / u32(number)) * u32(number - 1)
		}
	}
	answer := 1
	for number := 1; number <= limit; number += 1 {
		if i64(number) * i64(phi[answer]) > i64(answer) * i64(phi[number]) do answer = number
	}
	return i64(answer)
}
