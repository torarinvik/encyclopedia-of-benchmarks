module problem69

const max_limit = 1000000

@[export: 'problem69']
pub fn problem69(inclusive_limit i64) i64 {
	if inclusive_limit < 1 || inclusive_limit > max_limit { return -1 }
	limit := int(inclusive_limit)
	mut phi := []u32{len: limit + 1, init: 0}
	for value in 0 .. limit + 1 { phi[value] = u32(value) }
	for number in 2 .. limit + 1 {
		if phi[number] != u32(number) { continue }
		phi[number]--
		mut multiple := number * 2
		for multiple <= limit {
			phi[multiple] = (phi[multiple] / u32(number)) * u32(number - 1)
			multiple += number
		}
	}
	mut answer := 1
	for number in 1 .. limit + 1 {
		if i64(number) * i64(phi[answer]) > i64(answer) * i64(phi[number]) { answer = number }
	}
	return i64(answer)
}
