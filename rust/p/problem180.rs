/// Exact golden-triple fraction enumeration for Project Euler 180.
const MAX_ORDER: i64 = 35;
const HASH_CAPACITY: usize = 1 << 19;
const BIG_BASE: i64 = 10_000;
const BIG_LIMBS: usize = 8;

fn gcd_i64(mut left: i64, mut right: i64) -> i64 {
    while right != 0 { let remainder = left % right; left = right; right = remainder; }
    left
}
fn integer_sqrt(value: i64) -> i64 {
    if value <= 0 { return 0; }
    let mut root = value;
    let mut next = (root + value / root) / 2;
    while next < root { root = next; next = (root + value / root) / 2; }
    root
}
fn insert_fraction(nums: &mut [i64], dens: &mut [i64], numerator: i64, denominator: i64) -> bool {
    let mut index = (((numerator % HASH_CAPACITY as i64) * 1009 + denominator % HASH_CAPACITY as i64)
        % HASH_CAPACITY as i64) as usize;
    while dens[index] != 0 {
        if nums[index] == numerator && dens[index] == denominator { return false; }
        index = (index + 1) % HASH_CAPACITY;
    }
    nums[index] = numerator; dens[index] = denominator; true
}
fn record_sum(nums: &mut [i64], dens: &mut [i64], xn: i64, xd: i64, yn: i64, yd: i64,
              zn_input: i64, zd_input: i64, order: i64) {
    if zn_input <= 0 || zd_input <= 0 { return; }
    let mut zn = zn_input; let mut zd = zd_input;
    let mut divisor = gcd_i64(zn, zd); zn /= divisor; zd /= divisor;
    if zn >= zd || zd > order { return; }
    let sum_num = xn * yd * zd + yn * xd * zd + zn * xd * yd;
    let sum_den = xd * yd * zd; divisor = gcd_i64(sum_num, sum_den);
    insert_fraction(nums, dens, sum_num / divisor, sum_den / divisor);
}

#[no_mangle]
pub extern "C" fn problem180(order: i64) -> i64 {
    if order < 1 || order > MAX_ORDER { return -1; }
    let mut nums = vec![0i64; HASH_CAPACITY];
    let mut dens = vec![0i64; HASH_CAPACITY];
    let mut xn = 1;
    while xn <= order {
        let mut xd = xn + 1;
        while xd <= order {
            if gcd_i64(xn, xd) == 1 {
                let mut yn = 1;
                while yn <= order {
                    let mut yd = yn + 1;
                    while yd <= order {
                        if gcd_i64(yn, yd) == 1 && xn * yd <= yn * xd {
                            let mut zn = xn * yd + xd * yn; let mut zd = xd * yd;
                            record_sum(&mut nums, &mut dens, xn, xd, yn, yd, zn, zd, order);
                            let mut square_num = xn*xn*yd*yd + xd*xd*yn*yn;
                            let mut square_den = xd*xd*yd*yd;
                            let mut root_num = integer_sqrt(square_num); let mut root_den = integer_sqrt(square_den);
                            if root_num*root_num == square_num && root_den*root_den == square_den {
                                record_sum(&mut nums, &mut dens, xn, xd, yn, yd, root_num, root_den, order);
                            }
                            zn = xn * yn; zd = xd * yn + xn * yd;
                            record_sum(&mut nums, &mut dens, xn, xd, yn, yd, zn, zd, order);
                            square_num = xn*xn*yn*yn;
                            square_den = xd*xd*yn*yn + xn*xn*yd*yd;
                            root_num = integer_sqrt(square_num); root_den = integer_sqrt(square_den);
                            if root_num*root_num == square_num && root_den*root_den == square_den {
                                record_sum(&mut nums, &mut dens, xn, xd, yn, yd, root_num, root_den, order);
                            }
                        }
                        yd += 1;
                    }
                    yn += 1;
                }
            }
            xd += 1;
        }
        xn += 1;
    }
    let mut common = 1i64;
    let mut factor = 2;
    while factor <= order { common = common / gcd_i64(common, factor) * factor; factor += 1; }
    let mut total = [0i64; BIG_LIMBS];
    for i in 0..HASH_CAPACITY {
        if dens[i] == 0 { continue; }
        if common % dens[i] != 0 { return -1; }
        let mut carry = nums[i] * (common / dens[i]);
        let mut limb = 0;
        while carry > 0 { let current = total[limb] + carry; total[limb] = current % BIG_BASE; carry = current / BIG_BASE; limb += 1; }
    }
    let mut remainder = 0i64;
    for i in (0..BIG_LIMBS).rev() { remainder = (remainder * BIG_BASE + total[i]) % common; }
    let divisor = gcd_i64(remainder, common); remainder = 0;
    for i in (0..BIG_LIMBS).rev() { let current = remainder * BIG_BASE + total[i]; total[i] = current / divisor; remainder = current % divisor; }
    let mut numerator = 0i64;
    for i in (0..BIG_LIMBS).rev() {
        let limb = total[i];
        if numerator > (i64::MAX - limb) / BIG_BASE { return -1; }
        numerator = numerator * BIG_BASE + limb;
    }
    let denominator = common / divisor;
    if numerator > i64::MAX - denominator { return -1; }
    numerator + denominator
}
