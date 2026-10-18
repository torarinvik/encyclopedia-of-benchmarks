const MAX_DIGITS: usize = 64;
const MAX_OUTPUT_DIGITS: usize = 1664;

fn trim(value: &mut Vec<u32>) {
    while value.last() == Some(&0) { value.pop(); }
}

fn from_small(mut value: u32, base: u32) -> Vec<u32> {
    let mut result = Vec::new();
    while value != 0 { result.push(value % base); value /= base; }
    result
}

fn add(left: &mut Vec<u32>, right: &[u32], base: u32) {
    let mut index = 0;
    let mut carry = 0u64;
    while index < right.len() || carry != 0 {
        let sum = carry + left.get(index).copied().unwrap_or(0) as u64 +
                  right.get(index).copied().unwrap_or(0) as u64;
        if index == left.len() { left.push(0); }
        left[index] = (sum % base as u64) as u32;
        carry = sum / base as u64;
        index += 1;
    }
    if left.len() < right.len() { left.resize(right.len(), 0); }
}

fn multiply(left: &[u32], right: &[u32], base: u32) -> Vec<u32> {
    if left.is_empty() || right.is_empty() { return Vec::new(); }
    let mut result = vec![0u32; left.len() + right.len()];
    for i in 0..left.len() {
        let mut carry = 0u64;
        for j in 0..right.len() {
            let at = i + j;
            let product = left[i] as u64 * right[j] as u64 + result[at] as u64 + carry;
            result[at] = (product % base as u64) as u32;
            carry = product / base as u64;
        }
        let mut at = i + right.len();
        while carry != 0 {
            let sum = result[at] as u64 + carry;
            result[at] = (sum % base as u64) as u32;
            carry = sum / base as u64;
            at += 1;
            if at > result.len() { result.resize(at, 0); }
        }
    }
    trim(&mut result);
    result
}

fn power(mut factor: Vec<u32>, mut exponent: usize, base: u32) -> Vec<u32> {
    let mut result = from_small(1, base);
    while exponent > 0 {
        if exponent & 1 != 0 { result = multiply(&result, &factor, base); }
        exponent >>= 1;
        if exponent > 0 { factor = multiply(&factor, &factor, base); }
    }
    result
}

fn convert_base(digits: &[u32], source_base: u32, target_base: u32) -> Vec<u32> {
    if digits.is_empty() { return Vec::new(); }
    if source_base == target_base { return digits.to_vec(); }
    if digits.len() == 1 { return from_small(digits[0], target_base); }
    let middle = digits.len() / 2;
    let mut low = convert_base(&digits[..middle], source_base, target_base);
    let high = convert_base(&digits[middle..], source_base, target_base);
    let scale = power(from_small(source_base, target_base), middle, target_base);
    let shifted = multiply(&high, &scale, target_base);
    add(&mut low, &shifted, target_base);
    low
}

#[no_mangle]
pub unsafe extern "C" fn uint_convert_base(
    input: *const i64, input_length: usize, output: *mut u8, output_capacity: usize,
) -> i64 {
    if input.is_null() || input_length < 3 || input_length > MAX_DIGITS + 4 { return -1; }
    let values = std::slice::from_raw_parts(input, input_length);
    let source_value = values[0];
    let target_value = values[1];
    let count_value = values[2];
    if !(2..=(1i64 << 26)).contains(&source_value) || !(2..=(1i64 << 26)).contains(&target_value) ||
        !(0..=MAX_DIGITS as i64).contains(&count_value) || input_length != count_value as usize + 3 { return -1; }
    let source_base = source_value as u32;
    let target_base = target_value as u32;
    let count = count_value as usize;
    let mut digits = Vec::with_capacity(count);
    for &digit in &values[3..] {
        if digit < 0 || digit >= source_value { return -1; }
        digits.push(digit as u32);
    }
    if count > 0 && digits[count - 1] == 0 { return -1; }
    let converted = convert_base(&digits, source_base, target_base);
    if converted.len() > MAX_OUTPUT_DIGITS { return -1; }
    let bytes = converted.len() * 4;
    if output.is_null() || output_capacity < bytes { return -2; }
    for (index, digit) in converted.iter().enumerate() {
        for byte in 0..4 { *output.add(index * 4 + byte) = (digit >> (byte * 8)) as u8; }
    }
    bytes as i64
}
