const MAX_LIMIT: i64 = 1_000_000;

#[no_mangle]
pub extern "C" fn problem69(inclusive_limit: i64) -> i64 {
    if inclusive_limit < 1 || inclusive_limit > MAX_LIMIT { return -1; }
    let limit = inclusive_limit as usize;
    let mut phi = vec![0u32; limit + 1];
    for (value, item) in phi.iter_mut().enumerate() { *item = value as u32; }
    for number in 2..=limit {
        if phi[number] != number as u32 { continue; }
        phi[number] -= 1;
        let mut multiple = number * 2;
        while multiple <= limit {
            phi[multiple] = (phi[multiple] / number as u32) * (number - 1) as u32;
            multiple += number;
        }
    }
    let mut answer = 1usize;
    for number in 1..=limit {
        if (number as u64) * u64::from(phi[answer]) > (answer as u64) * u64::from(phi[number]) {
            answer = number;
        }
    }
    answer as i64
}
