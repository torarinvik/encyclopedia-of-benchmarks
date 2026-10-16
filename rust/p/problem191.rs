#[no_mangle]
pub extern "C" fn problem191(days: i64) -> i64 {
    if days < 0 || days > 65 { return -1; }
    let mut ways = [0_i64; 396];
    for absent in 0..=1 { for late in 0..=2 { ways[absent * 3 + late] = 1; } }
    for remaining in 1..=days {
        for absent in 0..=1 {
            for late in 0..=2 {
                let previous = ((remaining - 1) * 6) as usize;
                let late_state = if late < 2 { ways[previous + absent * 3 + late + 1] } else { 0 };
                let absent_state = if absent == 0 { ways[previous + 3] } else { 0 };
                let on_time_state = ways[previous + absent * 3];
                ways[(remaining * 6) as usize + absent * 3 + late] = late_state + absent_state + on_time_state;
            }
        }
    }
    ways[(days * 6) as usize]
}
