const MAX_ITEMS: usize = 64;
const MAX_PRICE: i64 = 1_000_000;

#[no_mangle]
pub unsafe extern "C" fn wine_problem_tabulated(prices: *const i64, length: usize) -> i64 {
    if prices.is_null() || length == 0 || length > MAX_ITEMS {
        return -1;
    }
    let values = std::slice::from_raw_parts(prices, length);
    if values.iter().any(|&price| !(0..=MAX_PRICE).contains(&price)) {
        return -1;
    }
    let mut table = [0_i64; MAX_ITEMS * MAX_ITEMS];
    for width in 1..=length {
        let year = (length - width + 1) as i64;
        for first in 0..=length - width {
            let last = first + width - 1;
            let slot = first * MAX_ITEMS + last;
            if first == last {
                table[slot] = values[first] * year;
            } else {
                let sell_first = values[first] * year + table[(first + 1) * MAX_ITEMS + last];
                let sell_last = values[last] * year + table[first * MAX_ITEMS + last - 1];
                table[slot] = sell_first.max(sell_last);
            }
        }
    }
    table[length - 1]
}
