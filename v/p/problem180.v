module problem180

const max_order = i64(35)
const hash_capacity = 1 << 19
const big_base = i64(10000)
const big_limbs = 8

fn gcd_i64(left_input i64, right_input i64) i64 {
	mut left := left_input
	mut right := right_input
	for right != 0 {
		remainder := left % right
		left = right
		right = remainder
	}
	return left
}
fn integer_sqrt(value i64) i64 {
	if value <= 0 { return 0 }
	mut root := value
	mut next := (root + value / root) / 2
	for next < root {
		root = next
		next = (root + value / root) / 2
	}
	return root
}
fn insert_fraction(mut nums []i64, mut dens []i64, numerator i64, denominator i64) bool {
	mut index := int(((numerator % i64(hash_capacity)) * 1009 + denominator % i64(hash_capacity)) % i64(hash_capacity))
	for dens[index] != 0 {
		if nums[index] == numerator && dens[index] == denominator { return false }
		index = (index + 1) % hash_capacity
	}
	nums[index] = numerator
	dens[index] = denominator
	return true
}
fn record_sum(mut nums []i64, mut dens []i64, xn i64, xd i64, yn i64, yd i64, zn_input i64, zd_input i64, order i64) {
	if zn_input <= 0 || zd_input <= 0 { return }
	mut zn := zn_input
	mut zd := zd_input
	mut divisor := gcd_i64(zn, zd)
	zn /= divisor
	zd /= divisor
	if zn >= zd || zd > order { return }
	 sum_num := xn * yd * zd + yn * xd * zd + zn * xd * yd
	 sum_den := xd * yd * zd
	divisor = gcd_i64(sum_num, sum_den)
	_ = insert_fraction(mut nums, mut dens, sum_num / divisor, sum_den / divisor)
}

@[export: 'problem180']
pub fn problem180(order i64) i64 {
	if order < 1 || order > max_order { return -1 }
	mut nums := []i64{len: hash_capacity, init: 0}
	mut dens := []i64{len: hash_capacity, init: 0}
	mut xn := i64(1)
	for xn <= order {
		mut xd := xn + 1
		for xd <= order {
			if gcd_i64(xn, xd) == 1 {
				mut yn := i64(1)
				for yn <= order {
					mut yd := yn + 1
					for yd <= order {
						if gcd_i64(yn, yd) == 1 && xn * yd <= yn * xd {
							mut zn := xn * yd + xd * yn
							mut zd := xd * yd
							record_sum(mut nums, mut dens, xn, xd, yn, yd, zn, zd, order)
							mut square_num := xn*xn*yd*yd + xd*xd*yn*yn
							mut square_den := xd*xd*yd*yd
							mut root_num := integer_sqrt(square_num)
							mut root_den := integer_sqrt(square_den)
							if root_num*root_num == square_num && root_den*root_den == square_den {
								record_sum(mut nums, mut dens, xn, xd, yn, yd, root_num, root_den, order)
							}
							zn = xn * yn
							zd = xd * yn + xn * yd
							record_sum(mut nums, mut dens, xn, xd, yn, yd, zn, zd, order)
							square_num = xn*xn*yn*yn
							square_den = xd*xd*yn*yn + xn*xn*yd*yd
							root_num = integer_sqrt(square_num)
							root_den = integer_sqrt(square_den)
							if root_num*root_num == square_num && root_den*root_den == square_den {
								record_sum(mut nums, mut dens, xn, xd, yn, yd, root_num, root_den, order)
							}
						}
						yd++
					}
					yn++
				}
			}
			xd++
		}
		xn++
	}
	mut common := i64(1)
	mut factor := i64(2)
	for factor <= order {
		common = common / gcd_i64(common, factor) * factor
		factor++
	}
	mut total := [big_limbs]i64{}
	for i in 0 .. hash_capacity {
		if dens[i] == 0 { continue }
		if common % dens[i] != 0 { return -1 }
		mut carry := nums[i] * (common / dens[i])
		mut limb := 0
		for carry > 0 {
			current := total[limb] + carry
			total[limb] = current % big_base
			carry = current / big_base
			limb++
		}
	}
	mut remainder := i64(0)
	mut index := big_limbs
	for index > 0 {
		index--
		remainder = (remainder * big_base + total[index]) % common
	}
	divisor := gcd_i64(remainder, common)
	remainder = 0
	index = big_limbs
	for index > 0 {
		index--
		current := remainder * big_base + total[index]
		total[index] = current / divisor
		remainder = current % divisor
	}
	mut numerator := i64(0)
	index = big_limbs
	for index > 0 {
		index--
		limb := total[index]
		if numerator > (9223372036854775807 - limb) / big_base { return -1 }
		numerator = numerator * big_base + limb
	}
	denominator := common / divisor
	if numerator > 9223372036854775807 - denominator { return -1 }
	return numerator + denominator
}
