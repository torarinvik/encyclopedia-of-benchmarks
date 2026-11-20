const MAX_N: usize = 8;
const MAX_INPUT_LENGTH: usize = 58;
const PREFERENCE_STRIDE: usize = MAX_N + 1;

fn hasStableRoommates(n: usize, preferences_ptr: *const [MAX_N * PREFERENCE_STRIDE]usize,
    ranking_ptr: *const [MAX_N * MAX_N]usize) bool {
    const preferences = preferences_ptr.*;
    const ranking = ranking_ptr.*;
    var leftmost: [MAX_N]usize = @splat(0);
    var rightmost: [MAX_N]usize = @splat(0);
    var proposed_to: [MAX_N]bool = @splat(false);
    for (0..n) |person| {
        leftmost[person] = 0;
        rightmost[person] = n - 1;
    }

    var proposer: usize = 0;
    var next_choice: usize = 0;
    for (0..n) |start| {
        proposer = start;
        var steps: usize = 0;
        while (true) {
            if (leftmost[proposer] > rightmost[proposer] or leftmost[proposer] >= n) return false;
            next_choice = preferences[proposer * PREFERENCE_STRIDE + leftmost[proposer]];
            if (next_choice == proposer) return false;
            var current = preferences[next_choice * PREFERENCE_STRIDE + rightmost[next_choice]];
            while (ranking[next_choice * MAX_N + proposer] > ranking[next_choice * MAX_N + current]) {
                leftmost[proposer] += 1;
                if (leftmost[proposer] > rightmost[proposer] or leftmost[proposer] >= n) return false;
                next_choice = preferences[proposer * PREFERENCE_STRIDE + leftmost[proposer]];
                if (next_choice == proposer) return false;
                current = preferences[next_choice * PREFERENCE_STRIDE + rightmost[next_choice]];
            }
            rightmost[next_choice] = ranking[next_choice * MAX_N + proposer];
            proposer = current;
            if (!proposed_to[next_choice]) {
                proposed_to[next_choice] = true;
                break;
            }
            steps += 1;
            if (steps > n * n) return false;
        }
    }
    if (proposer != next_choice) return false;
    for (0..n) |person| {
        if (leftmost[person] > rightmost[person]) return false;
    }

    var second: [MAX_N]usize = @splat(0);
    for (0..n) |person| second[person] = leftmost[person] + 1;
    var first_unmatched: usize = 0;
    var first_in_cycle: usize = 0;
    var tail: [MAX_N]bool = @splat(false);
    var cycle: [MAX_N + 1]usize = @splat(0);

    while (true) {
        while (first_unmatched < n and leftmost[first_unmatched] == rightmost[first_unmatched]) {
            first_unmatched += 1;
        }
        if (first_unmatched >= n) {
            for (0..n) |person| {
                const partner = preferences[person * PREFERENCE_STRIDE + leftmost[person]];
                if (partner == person or preferences[partner * PREFERENCE_STRIDE + leftmost[partner]] != person) return false;
            }
            return true;
        }

        var visited = tail;
        var person: usize = first_unmatched;
        var position: usize = 0;
        if (first_in_cycle > 0) {
            person = cycle[first_in_cycle - 1];
            position = first_in_cycle - 1;
        }

        var repeated_person: usize = 0;
        while (true) {
            if (position >= MAX_N + 1) return false;
            cycle[position] = person;
            position += 1;
            visited[person] = true;

            var list_position = second[person];
            var choice: ?usize = null;
            while (list_position < n) {
                const candidate = preferences[person * PREFERENCE_STRIDE + list_position];
                list_position += 1;
                if (candidate == person) return false;
                if (ranking[candidate * MAX_N + person] <= rightmost[candidate]) {
                    choice = candidate;
                    break;
                }
            }
            if (choice == null) return false;
            const chosen = choice.?;
            second[person] = list_position - 1;
            const next_person = preferences[chosen * PREFERENCE_STRIDE + rightmost[chosen]];
            if (visited[next_person]) {
                repeated_person = next_person;
                break;
            }
            person = next_person;
        }

        const last_in_cycle = position - 1;
        tail = visited;
        var cycle_start = position;
        while (cycle_start > 0) {
            cycle_start -= 1;
            const member = cycle[cycle_start];
            tail[member] = false;
            if (member == repeated_person) {
                first_in_cycle = cycle_start;
                break;
            }
        }
        if (cycle_start == 0 and cycle[cycle_start] != repeated_person) return false;

        for (first_in_cycle..last_in_cycle + 1) |index| {
            const cycle_person = cycle[index];
            leftmost[cycle_person] = second[cycle_person];
            second[cycle_person] = leftmost[cycle_person] + 1;
            if (leftmost[cycle_person] >= n) return false;
            const next_choice_in_cycle = preferences[cycle_person * PREFERENCE_STRIDE + leftmost[cycle_person]];
            rightmost[next_choice_in_cycle] = ranking[next_choice_in_cycle * MAX_N + cycle_person];
        }
        for (first_in_cycle..last_in_cycle + 1) |index| {
            const cycle_person = cycle[index];
            if (leftmost[cycle_person] > rightmost[cycle_person]) return false;
        }
    }
}

export fn stable_roommates(input_opt: ?[*]const i64, length: usize) i64 {
    const input = input_opt orelse return -1;
    if (length < 1 or length > MAX_INPUT_LENGTH) return -1;
    const n_value = input[0];
    if (n_value < 2 or n_value > 8 or @mod(n_value, 2) != 0) return -1;
    const n: usize = @intCast(n_value);
    if (length != 1 + n * (n - 1)) return -1;

    var preferences: [MAX_N * PREFERENCE_STRIDE]usize = @splat(0);
    var ranking: [MAX_N * MAX_N]usize = @splat(0);
    var cursor: usize = 1;
    for (0..n) |person| {
        var seen: [MAX_N]bool = @splat(false);
        for (0..n - 1) |rank| {
            const choice_value = input[cursor];
            cursor += 1;
            if (choice_value < 0 or choice_value >= n_value or choice_value == @as(i64, @intCast(person))) return -1;
            const choice: usize = @intCast(choice_value);
            if (seen[choice]) return -1;
            seen[choice] = true;
            preferences[person * PREFERENCE_STRIDE + rank] = choice;
            ranking[person * MAX_N + choice] = rank;
        }
        preferences[person * PREFERENCE_STRIDE + n - 1] = person;
        ranking[person * MAX_N + person] = n - 1;
    }
    return if (hasStableRoommates(n, &preferences, &ranking)) 1 else 0;
}
