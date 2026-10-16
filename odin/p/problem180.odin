package problem180

MAX_ORDER :: i64(35)
HASH_CAPACITY :: 524288
BIG_BASE :: i64(10000)
BIG_LIMBS :: 8

problem180_gcd :: proc(left_input, right_input: i64) -> i64 {
    left, right := left_input, right_input
    for right != 0 { remainder := left % right; left = right; right = remainder }
    return left
}
problem180_integer_sqrt :: proc(value: i64) -> i64 {
    if value <= 0 do return 0
    root := value
    next := (root + value / root) / 2
    for next < root { root = next; next = (root + value / root) / 2 }
    return root
}
problem180_insert :: proc(nums, dens: []i64, numerator, denominator: i64) -> bool {
    index := int(((numerator % i64(HASH_CAPACITY)) * 1009 + denominator % i64(HASH_CAPACITY)) % i64(HASH_CAPACITY))
    for dens[index] != 0 {
        if nums[index] == numerator && dens[index] == denominator do return false
        index = (index + 1) % HASH_CAPACITY
    }
    nums[index] = numerator; dens[index] = denominator
    return true
}
problem180_record :: proc(nums, dens: []i64, xn, xd, yn, yd, zn_input, zd_input, order: i64) {
    if zn_input <= 0 || zd_input <= 0 do return
    zn, zd := zn_input, zd_input
    divisor := problem180_gcd(zn, zd); zn /= divisor; zd /= divisor
    if zn >= zd || zd > order do return
    sum_num := xn * yd * zd + yn * xd * zd + zn * xd * yd
    sum_den := xd * yd * zd
    divisor = problem180_gcd(sum_num, sum_den)
    _ = problem180_insert(nums, dens, sum_num / divisor, sum_den / divisor)
}

@(export)
problem180 :: proc "c" (order: i64) -> i64 {
    if order < 1 || order > MAX_ORDER do return -1
    nums := make([]i64, HASH_CAPACITY); defer delete(nums)
    dens := make([]i64, HASH_CAPACITY); defer delete(dens)
    for xn := i64(1); xn <= order; xn += 1 {
        for xd := xn + 1; xd <= order; xd += 1 {
            if problem180_gcd(xn, xd) != 1 do continue
            for yn := i64(1); yn <= order; yn += 1 {
                for yd := yn + 1; yd <= order; yd += 1 {
                    if problem180_gcd(yn, yd) != 1 || xn * yd > yn * xd do continue
                    zn, zd := xn * yd + xd * yn, xd * yd
                    problem180_record(nums, dens, xn, xd, yn, yd, zn, zd, order)
                    square_num := xn*xn*yd*yd + xd*xd*yn*yn
                    square_den := xd*xd*yd*yd
                    root_num, root_den := problem180_integer_sqrt(square_num), problem180_integer_sqrt(square_den)
                    if root_num*root_num == square_num && root_den*root_den == square_den {
                        problem180_record(nums, dens, xn, xd, yn, yd, root_num, root_den, order)
                    }
                    zn, zd = xn * yn, xd * yn + xn * yd
                    problem180_record(nums, dens, xn, xd, yn, yd, zn, zd, order)
                    square_num = xn*xn*yn*yn
                    square_den = xd*xd*yn*yn + xn*xn*yd*yd
                    root_num, root_den = problem180_integer_sqrt(square_num), problem180_integer_sqrt(square_den)
                    if root_num*root_num == square_num && root_den*root_den == square_den {
                        problem180_record(nums, dens, xn, xd, yn, yd, root_num, root_den, order)
                    }
                }
            }
        }
    }
    common := i64(1)
    for factor := i64(2); factor <= order; factor += 1 { common = common / problem180_gcd(common, factor) * factor }
    total: [BIG_LIMBS]i64 = {}
    for i := 0; i < HASH_CAPACITY; i += 1 {
        if dens[i] == 0 do continue
        if common % dens[i] != 0 do return -1
        carry := nums[i] * (common / dens[i])
        limb := 0
        for carry > 0 { current := total[limb] + carry; total[limb] = current % BIG_BASE; carry = current / BIG_BASE; limb += 1 }
    }
    remainder := i64(0)
    for index := BIG_LIMBS - 1; index >= 0; index -= 1 { remainder = (remainder * BIG_BASE + total[index]) % common }
    divisor := problem180_gcd(remainder, common); remainder = 0
    for index := BIG_LIMBS - 1; index >= 0; index -= 1 { current := remainder * BIG_BASE + total[index]; total[index] = current / divisor; remainder = current % divisor }
    numerator := i64(0)
    for index := BIG_LIMBS - 1; index >= 0; index -= 1 {
        limb := total[index]
        if numerator > (9223372036854775807 - limb) / BIG_BASE do return -1
        numerator = numerator * BIG_BASE + limb
    }
    denominator := common / divisor
    if numerator > 9223372036854775807 - denominator do return -1
    return numerator + denominator
}
