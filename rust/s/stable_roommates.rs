const MAX_N: usize = 8;
const MAX_INPUT_LENGTH: usize = 58;
const PREFERENCE_STRIDE: usize = MAX_N + 1;

fn has_stable_roommates(n: usize, preferences: &[usize; MAX_N * PREFERENCE_STRIDE], ranking: &[usize; MAX_N * MAX_N]) -> bool {
    let mut leftmost = [0usize; MAX_N];
    let mut rightmost = [0usize; MAX_N];
    let mut proposed_to = [false; MAX_N];
    for person in 0..n {
        leftmost[person] = 0;
        rightmost[person] = n - 1;
    }

    let (mut proposer, mut next_choice) = (0usize, 0usize);
    for start in 0..n {
        proposer = start;
        let mut steps = 0usize;
        loop {
            if leftmost[proposer] > rightmost[proposer] || leftmost[proposer] >= n { return false; }
            next_choice = preferences[proposer * PREFERENCE_STRIDE + leftmost[proposer]];
            if next_choice == proposer { return false; }
            let mut current = preferences[next_choice * PREFERENCE_STRIDE + rightmost[next_choice]];
            while ranking[next_choice * MAX_N + proposer] > ranking[next_choice * MAX_N + current] {
                leftmost[proposer] += 1;
                if leftmost[proposer] > rightmost[proposer] || leftmost[proposer] >= n { return false; }
                next_choice = preferences[proposer * PREFERENCE_STRIDE + leftmost[proposer]];
                if next_choice == proposer { return false; }
                current = preferences[next_choice * PREFERENCE_STRIDE + rightmost[next_choice]];
            }
            rightmost[next_choice] = ranking[next_choice * MAX_N + proposer];
            proposer = current;
            if !proposed_to[next_choice] {
                proposed_to[next_choice] = true;
                break;
            }
            steps += 1;
            if steps > n * n { return false; }
        }
    }
    if proposer != next_choice { return false; }
    for person in 0..n {
        if leftmost[person] > rightmost[person] { return false; }
    }

    let mut second = [0usize; MAX_N];
    for person in 0..n { second[person] = leftmost[person] + 1; }
    let mut first_unmatched = 0usize;
    let mut first_in_cycle = 0usize;
    let mut tail = [false; MAX_N];
    let mut cycle = [0usize; MAX_N + 1];

    loop {
        while first_unmatched < n && leftmost[first_unmatched] == rightmost[first_unmatched] {
            first_unmatched += 1;
        }
        if first_unmatched >= n {
            for person in 0..n {
                let partner = preferences[person * PREFERENCE_STRIDE + leftmost[person]];
                if partner == person || preferences[partner * PREFERENCE_STRIDE + leftmost[partner]] != person { return false; }
            }
            return true;
        }

        let mut visited = tail;
        let (mut person, mut position) = if first_in_cycle > 0 {
            (cycle[first_in_cycle - 1], first_in_cycle - 1)
        } else {
            (first_unmatched, 0)
        };
        let repeated_person;
        loop {
            if position >= MAX_N + 1 { return false; }
            cycle[position] = person;
            position += 1;
            visited[person] = true;

            let mut list_position = second[person];
            let mut choice = None;
            while list_position < n {
                let candidate = preferences[person * PREFERENCE_STRIDE + list_position];
                list_position += 1;
                if candidate == person { return false; }
                if ranking[candidate * MAX_N + person] <= rightmost[candidate] {
                    choice = Some(candidate);
                    break;
                }
            }
            let choice = match choice { Some(value) => value, None => return false };
            second[person] = list_position - 1;
            let next_person = preferences[choice * PREFERENCE_STRIDE + rightmost[choice]];
            if visited[next_person] {
                repeated_person = next_person;
                break;
            }
            person = next_person;
        }

        let last_in_cycle = position - 1;
        tail = visited;
        let mut cycle_start = position;
        while cycle_start > 0 {
            cycle_start -= 1;
            let member = cycle[cycle_start];
            tail[member] = false;
            if member == repeated_person {
                first_in_cycle = cycle_start;
                break;
            }
        }
        if cycle_start == 0 && cycle[cycle_start] != repeated_person { return false; }

        for index in first_in_cycle..=last_in_cycle {
            let cycle_person = cycle[index];
            leftmost[cycle_person] = second[cycle_person];
            second[cycle_person] = leftmost[cycle_person] + 1;
            if leftmost[cycle_person] >= n { return false; }
            let next_choice_in_cycle = preferences[cycle_person * PREFERENCE_STRIDE + leftmost[cycle_person]];
            rightmost[next_choice_in_cycle] = ranking[next_choice_in_cycle * MAX_N + cycle_person];
        }
        for index in first_in_cycle..=last_in_cycle {
            let cycle_person = cycle[index];
            if leftmost[cycle_person] > rightmost[cycle_person] { return false; }
        }
    }
}

#[no_mangle]
pub unsafe extern "C" fn stable_roommates(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 1 || length > MAX_INPUT_LENGTH { return -1; }
    let n_value = *input;
    if n_value < 2 || n_value > MAX_N as i64 || n_value % 2 != 0 { return -1; }
    let n = n_value as usize;
    if length != 1 + n * (n - 1) { return -1; }

    let mut preferences = [0usize; MAX_N * PREFERENCE_STRIDE];
    let mut ranking = [0usize; MAX_N * MAX_N];
    let mut cursor = 1usize;
    for person in 0..n {
        let mut seen = [false; MAX_N];
        for rank in 0..n - 1 {
            let choice_value = *input.add(cursor);
            cursor += 1;
            if choice_value < 0 || choice_value >= n_value || choice_value == person as i64 { return -1; }
            let choice = choice_value as usize;
            if seen[choice] { return -1; }
            seen[choice] = true;
            preferences[person * PREFERENCE_STRIDE + rank] = choice;
            ranking[person * MAX_N + choice] = rank;
        }
        preferences[person * PREFERENCE_STRIDE + n - 1] = person;
        ranking[person * MAX_N + person] = n - 1;
    }
    if has_stable_roommates(n, &preferences, &ranking) { 1 } else { 0 }
}
