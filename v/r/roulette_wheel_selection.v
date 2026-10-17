const max_input_values = usize(131)
const max_validators = 128
const max_stake = i64(1_000_000)
const max_total_stake = i64(128_000_000)

@[export: 'roulette_wheel_selection']
pub fn roulette_wheel_selection(input &i64, length usize) i64 {
    if unsafe { input == nil } || length < 3 || length > max_input_values { return -1 }
    unsafe {
        count_value := input[0]
        if count_value < 1 || count_value > i64(max_validators) { return -1 }
        count := int(count_value)
        if length != usize(count + 2) { return -1 }

        mut total := i64(0)
        for index in 0 .. count {
            stake := input[1 + index]
            if stake < 1 || stake > max_stake { return -1 }
            if total > max_total_stake - stake { return -1 }
            total += stake
        }

        ticket := input[1 + count]
        if ticket < 0 || ticket >= total { return -1 }

        mut cumulative := i64(0)
        for index in 0 .. count {
            cumulative += input[1 + index]
            if ticket < cumulative { return i64(index + 1) }
        }
        return -1
    }
}
