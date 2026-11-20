const MAX_TERMS: usize = 16;
const MAX_LENGTH: usize = 34;
const MAX_MANTISSA: i64 = 16_777_216;
const OUTPUT_SCALE: f64 = 1_073_741_824.0;

fn two_sum(a: f64, b: f64) -> (f64, f64) {
    let rounded = a+b;
    let b_virtual = rounded-a;
    let a_virtual = rounded-b_virtual;
    let b_roundoff = b-b_virtual;
    let a_roundoff = a-a_virtual;
    (rounded,a_roundoff+b_roundoff)
}

fn grow_expansion(expansion: &[f64], value: f64, grown: &mut [f64; MAX_TERMS+1]) -> usize {
    let mut q = value;
    let mut grown_count = 0;
    for &component in expansion {
        let (high,low) = two_sum(q,component);
        if low != 0.0 {
            grown[grown_count] = low;
            grown_count += 1;
        }
        q = high;
    }
    if q != 0.0 || grown_count == 0 {
        grown[grown_count] = q;
        grown_count += 1;
    }
    grown_count
}

#[no_mangle]
pub unsafe extern "C" fn shewchuk_expansion_sum(input: *const i64, length: usize) -> i64 {
    if input.is_null() || !(1..=MAX_LENGTH).contains(&length) { return -1; }
    let words = std::slice::from_raw_parts(input,length);
    if words[0] < 0 || words[0] > MAX_TERMS as i64 { return -1; }
    let n = words[0] as usize;
    if length != 1+2*n { return -1; }

    let mut expansion = [0.0_f64; MAX_TERMS+1];
    let mut grown = [0.0_f64; MAX_TERMS+1];
    let mut expansion_count = 0;
    for i in 0..n {
        let mantissa = words[1+2*i];
        let exponent = words[2+2*i];
        if !(-MAX_MANTISSA..=MAX_MANTISSA).contains(&mantissa) || !(-30..=0).contains(&exponent) { return -1; }
        let mut value = mantissa as f64;
        let mut shift = 0_i64;
        while shift > exponent {
            value *= 0.5;
            shift -= 1;
        }
        if value != 0.0 {
            let grown_count = grow_expansion(&expansion[..expansion_count],value,&mut grown);
            expansion[..grown_count].copy_from_slice(&grown[..grown_count]);
            expansion_count = grown_count;
        }
    }
    let mut result = (1_i64 << 58)+1;
    for &component in &expansion[..expansion_count] {
        result += (component*OUTPUT_SCALE) as i64;
    }
    result
}
