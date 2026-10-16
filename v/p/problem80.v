module problem80

const limbs = 16
const base = u64(1_000_000_000)
fn mul_add(src []u64, factor u64, add u64, mut dst []u64) {
	mut carry := add
	for i in 0 .. limbs { value := src[i] * factor + carry; dst[i] = value % base; carry = value / base }
}
fn ge(left []u64, right []u64) bool {
	for index in 0 .. limbs { i := limbs - 1 - index; if left[i] != right[i] { return left[i] > right[i] } }
	return true
}
fn subtract(mut left []u64, right []u64) {
	mut borrow := u64(0)
	for i in 0 .. limbs { amount := right[i] + borrow; if left[i] < amount { left[i] = left[i] + base - amount; borrow = 1 } else { left[i] -= amount; borrow = 0 } }
}

@[export: 'problem80']
pub fn problem80(placeholder i64) i64 {
	if placeholder != 0 { return -1 }
	mut answer := i64(0)
	for number in u64(2) .. u64(100) {
		mut integer_root := u64(0)
		for (integer_root + 1) * (integer_root + 1) <= number { integer_root++ }
		if integer_root * integer_root == number { continue }
		mut root := []u64{len: limbs}; mut remainder := []u64{len: limbs}; mut scaled := []u64{len: limbs}; mut trial := []u64{len: limbs}
		mut digit_sum := i64(0)
		for step in 0 .. 100 {
			mul_add(root, 100, if step == 0 { number } else { u64(0) }, mut remainder)
			mut digit := i64(9)
			for digit >= 0 { mul_add(root, 20, u64(digit), mut scaled); mul_add(scaled, u64(digit), 0, mut trial); if ge(remainder, trial) { break }; digit-- }
			subtract(mut remainder, trial)
			mul_add(root, 10, u64(digit), mut root)
			digit_sum += digit
		}
		answer += digit_sum
	}
	return answer
}
