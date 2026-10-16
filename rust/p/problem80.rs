const LIMBS: usize = 16;
const BASE: u64 = 1_000_000_000;
type Big = [u64; LIMBS];

fn mul_add(src: &Big, factor: u64, add: u64, dst: &mut Big) {
    let mut carry = add;
    for i in 0..LIMBS {
        let value = src[i] * factor + carry;
        dst[i] = value % BASE;
        carry = value / BASE;
    }
}
fn ge(left: &Big, right: &Big) -> bool {
    for i in (0..LIMBS).rev() { if left[i] != right[i] { return left[i] > right[i]; } }
    true
}
fn subtract(left: &mut Big, right: &Big) {
    let mut borrow = 0;
    for i in 0..LIMBS {
        let amount = right[i] + borrow;
        if left[i] < amount { left[i] = left[i] + BASE - amount; borrow = 1; }
        else { left[i] -= amount; borrow = 0; }
    }
}

#[no_mangle]
pub extern "C" fn problem80(placeholder: i64) -> i64 {
    if placeholder != 0 { return -1; }
    let mut answer = 0i64;
    for number in 2u64..100 {
        let mut integer_root = 0;
        while (integer_root + 1) * (integer_root + 1) <= number { integer_root += 1; }
        if integer_root * integer_root == number { continue; }
        let (mut root, mut remainder, mut scaled, mut trial): (Big, Big, Big, Big) = ([0; LIMBS], [0; LIMBS], [0; LIMBS], [0; LIMBS]);
        let mut digit_sum = 0i64;
        for step in 0..100 {
            let mut next_remainder = [0u64; LIMBS];
            mul_add(&remainder, 100, if step == 0 { number } else { 0 }, &mut next_remainder);
            remainder = next_remainder;
            let mut digit = 9i64;
            while digit >= 0 {
                mul_add(&root, 20, digit as u64, &mut scaled);
                mul_add(&scaled, digit as u64, 0, &mut trial);
                if ge(&remainder, &trial) { break; }
                digit -= 1;
            }
            subtract(&mut remainder, &trial);
            let mut next_root = [0u64; LIMBS];
            mul_add(&root, 10, digit as u64, &mut next_root);
            root = next_root;
            digit_sum += digit;
        }
        answer += digit_sum;
    }
    answer
}
