module volume

const MaxDimension = 1000
const InvalidResult = i64(-1)

@[export: 'volume']
pub fn volume(input &i64, length usize) i64 {
	if length != 4 { return InvalidResult }
	unsafe {
		operation := input[0]
		a, b, c := input[1], input[2], input[3]
		if a < 0 || a > MaxDimension || b < 0 || b > MaxDimension || c < 0 || c > MaxDimension { return InvalidResult }
		if operation == 0 {
			if b != 0 || c != 0 { return InvalidResult }
			return a * a * a
		}
		if operation == 1 { return a * b * c }
		if operation == 2 {
			product := a * b * c
			if product % 2 != 0 { return InvalidResult }
			return product / 2
		}
		if operation == 3 {
			product := a * b * c
			if product % 3 != 0 { return InvalidResult }
			return product / 3
		}
		return InvalidResult
	}
}
