package problem80

Base :: u64(1_000_000_000)
LIMBS :: 16
Big :: [LIMBS]u64

mul_add :: proc(src: []u64, factor, add: u64, dst: []u64) {
	carry := add
	for i := 0; i < LIMBS; i += 1 { value := src[i] * factor + carry; dst[i] = value % Base; carry = value / Base }
}
ge :: proc(left, right: []u64) -> bool {
	for i := LIMBS - 1; i >= 0; i -= 1 { if left[i] != right[i] { return left[i] > right[i] } }
	return true
}
subtract :: proc(left, right: []u64) {
	borrow := u64(0)
	for i := 0; i < LIMBS; i += 1 { amount := right[i] + borrow; if left[i] < amount { left[i] = left[i] + Base - amount; borrow = 1 } else { left[i] -= amount; borrow = 0 } }
}

@(export)
problem80 :: proc "c" (placeholder: i64) -> i64 {
	if placeholder != 0 do return -1
	answer := i64(0)
	for number := u64(2); number < 100; number += 1 {
		integer_root := u64(0)
		for (integer_root + 1) * (integer_root + 1) <= number { integer_root += 1 }
		if integer_root * integer_root == number do continue
		root, remainder, scaled, trial: Big = {}, {}, {}, {}
		digit_sum := i64(0)
		for step := 0; step < 100; step += 1 {
			mul_add(remainder[:], 100, if step == 0 then number else 0, remainder[:])
			digit := i64(9)
			for digit >= 0 {
				mul_add(root[:], 20, u64(digit), scaled[:])
				mul_add(scaled[:], u64(digit), 0, trial[:])
				if ge(remainder[:], trial[:]) do break
				digit -= 1
			}
			subtract(remainder[:], trial[:])
			mul_add(root[:], 10, u64(digit), root[:])
			digit_sum += digit
		}
		answer += digit_sum
	}
	return answer
}
