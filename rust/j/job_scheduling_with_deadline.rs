const MAX_JOBS: usize = 128;
const MAX_INPUT_LENGTH: usize = 1 + 4 * MAX_JOBS;
const MAX_ID: i64 = 2_147_483_647;
const MAX_PROFIT: i64 = 1_000_000;
const PACK_BASE: i64 = 4_294_967_296;

#[no_mangle]
pub unsafe extern "C" fn job_scheduling_with_deadline(packed: *const i64, length: usize) -> i64 {
    if packed.is_null() || length < 1 || length > MAX_INPUT_LENGTH { return -1; }
    let packed = unsafe { std::slice::from_raw_parts(packed, length) };
    let count_value = packed[0];
    if !(0..=MAX_JOBS as i64).contains(&count_value) ||
        length != 1 + count_value as usize * 4 { return -1; }
    let count = count_value as usize;

    let mut ids = [0i64; MAX_JOBS];
    let mut arrivals = [0i64; MAX_JOBS];
    let mut deadlines = [0i64; MAX_JOBS];
    let mut profits = [0i64; MAX_JOBS];
    let mut max_deadline = 0i64;
    for i in 0..count {
        let base = 1 + i * 4;
        ids[i] = packed[base];
        arrivals[i] = packed[base + 1];
        deadlines[i] = packed[base + 2];
        profits[i] = packed[base + 3];
        if !(0..=MAX_ID).contains(&ids[i]) ||
            !(1..=32).contains(&arrivals[i]) ||
            !(1..=32).contains(&deadlines[i]) ||
            !(-MAX_PROFIT..=MAX_PROFIT).contains(&profits[i]) { return -1; }
        if ids[..i].contains(&ids[i]) { return -1; }
        max_deadline = max_deadline.max(deadlines[i]);
    }

    // Stable insertion sort preserves input order for equal profits.
    for i in 1..count {
        let key_id = ids[i];
        let key_arrival = arrivals[i];
        let key_deadline = deadlines[i];
        let key_profit = profits[i];
        let mut position = i;
        while position > 0 && profits[position - 1] < key_profit {
            ids[position] = ids[position - 1];
            arrivals[position] = arrivals[position - 1];
            deadlines[position] = deadlines[position - 1];
            profits[position] = profits[position - 1];
            position -= 1;
        }
        ids[position] = key_id;
        arrivals[position] = key_arrival;
        deadlines[position] = key_deadline;
        profits[position] = key_profit;
    }

    let mut occupied = [false; 32];
    let mut scheduled = 0i64;
    let mut total_profit = 0i64;
    for i in 0..count {
        if arrivals[i] > deadlines[i] { continue; }
        let last_slot = (deadlines[i] - 1).min(max_deadline - 1);
        let mut slot = last_slot;
        while slot >= arrivals[i] - 1 {
            let index = slot as usize;
            if !occupied[index] {
                occupied[index] = true;
                scheduled += 1;
                total_profit += profits[i];
                break;
            }
            slot -= 1;
        }
    }

    let low_word = if total_profit < 0 { total_profit + PACK_BASE } else { total_profit };
    scheduled * PACK_BASE + low_word
}
