const MAX_N: usize = 8;
const MAX_INPUT_LENGTH: usize = 66;

#[no_mangle]
pub unsafe extern "C" fn housing_top_trading_cycles(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT_LENGTH {
        return -1;
    }
    let values = unsafe { core::slice::from_raw_parts(input, length) };
    let n_value = values[0];
    if !(1..=MAX_N as i64).contains(&n_value) {
        return -1;
    }
    let n = n_value as usize;
    if length != 1 + n * n {
        return -1;
    }

    let mut preferences = [[0usize; MAX_N]; MAX_N];
    let mut cursor = 1usize;
    for agent in 0..n {
        let mut seen = [false; MAX_N];
        for rank in 0..n {
            let house_value = values[cursor];
            cursor += 1;
            if house_value < 0 || house_value >= n_value {
                return -1;
            }
            let house = house_value as usize;
            if seen[house] {
                return -1;
            }
            seen[house] = true;
            preferences[agent][rank] = house;
        }
    }

    let mut agent_active = [false; MAX_N];
    let mut house_active = [false; MAX_N];
    let mut allocation = [0usize; MAX_N];
    for index in 0..n {
        agent_active[index] = true;
        house_active[index] = true;
    }
    let mut active_count = n;
    while active_count > 0 {
        let mut choice = [0usize; MAX_N];
        for agent in 0..n {
            if !agent_active[agent] {
                continue;
            }
            let mut selected = None;
            for rank in 0..n {
                let house = preferences[agent][rank];
                if house_active[house] {
                    selected = Some(house);
                    break;
                }
            }
            let Some(house) = selected else { return -1 };
            choice[agent] = house;
        }

        // Contract each agent -> chosen house -> owner pair into one agent edge.
        let mut state = [0u8; MAX_N];
        let mut path_position = [-1i32; MAX_N];
        let mut selected_this_round = [false; MAX_N];
        let mut path = [0usize; MAX_N];
        for start in 0..n {
            if !agent_active[start] || state[start] != 0 {
                continue;
            }
            let mut current = start;
            let mut path_length = 0usize;
            while state[current] == 0 {
                state[current] = 1;
                path_position[current] = path_length as i32;
                path[path_length] = current;
                path_length += 1;
                current = choice[current];
            }
            if state[current] == 1 {
                let cycle_start = path_position[current] as usize;
                for index in cycle_start..path_length {
                    selected_this_round[path[index]] = true;
                }
            }
            for index in 0..path_length {
                state[path[index]] = 2;
                path_position[path[index]] = -1;
            }
        }

        let mut removed = 0usize;
        for agent in 0..n {
            if selected_this_round[agent] {
                allocation[agent] = choice[agent];
                agent_active[agent] = false;
                house_active[choice[agent]] = false;
                removed += 1;
            }
        }
        if removed == 0 {
            return -1;
        }
        active_count -= removed;
    }

    let mut packed = 1i64;
    for agent in 0..n {
        packed += (allocation[agent] as i64) << (3 * agent);
    }
    packed
}
