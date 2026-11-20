const MAX_TARGET: i64 = 127;
const MAX_INPUT_LENGTH: usize = 2;

#[no_mangle]
pub unsafe extern "C" fn race_car_minimum_instruction_count(
    input: *const i64,
    length: usize,
) -> i64 {
    if input.is_null() || length < 1 || length > MAX_INPUT_LENGTH || length != 1 {
        return -1;
    }
    let target_value = *input;
    if !(0..=MAX_TARGET).contains(&target_value) {
        return -1;
    }
    let target = target_value as usize;
    let mut distance = [0i32; 128];

    for position in 1..=target {
        let mut run = 0usize;
        let mut upper_power = 1usize;
        while upper_power <= position {
            upper_power *= 2;
            run += 1;
        }
        let upper = upper_power - 1;
        if position == upper {
            distance[position] = run as i32;
            continue;
        }

        let mut best = (run + 1) as i32 + distance[upper - position];
        let lower = upper_power / 2 - 1;
        let mut backward_run = 0usize;
        let mut backward_power = 1usize;
        while backward_run + 1 < run {
            let backward_distance = backward_power - 1;
            let remaining = position - (lower - backward_distance);
            let candidate = (run + backward_run + 1) as i32 + distance[remaining];
            if candidate < best {
                best = candidate;
            }
            backward_power *= 2;
            backward_run += 1;
        }
        distance[position] = best;
    }
    distance[target] as i64
}
