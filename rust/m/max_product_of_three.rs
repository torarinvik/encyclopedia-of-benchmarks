#[no_mangle]
pub extern "C" fn max_product_of_three(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length == 0 { return i64::MIN; }
    let packed = unsafe { std::slice::from_raw_parts(input, length) };
    if !(3..=128).contains(&packed[0]) || length != packed[0] as usize + 1 { return i64::MIN; }
    let n = packed[0] as usize;
    if packed[1..].iter().any(|&value| !(-1000..=1000).contains(&value)) { return i64::MIN; }
    let mut max1 = packed[1]; let mut max2 = -1001; let mut max3 = -1001;
    let mut min1 = packed[1]; let mut min2 = 1001;
    for &value in &packed[2..=n] {
        if value > max1 { max3 = max2; max2 = max1; max1 = value; }
        else if value > max2 { max3 = max2; max2 = value; }
        else if value > max3 { max3 = value; }
        if value < min1 { min2 = min1; min1 = value; }
        else if value < min2 { min2 = value; }
    }
    let product1 = max1 * max2 * max3;
    let product2 = max1 * min1 * min2;
    product1.max(product2)
}
