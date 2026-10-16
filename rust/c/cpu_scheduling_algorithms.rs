fn better_choice(mode: i64, candidate: usize, best: usize,
                 arrival: &[i64; 32], burst: &[i64; 32],
                 remaining: &[i64; 32], priority: &[i64; 32]) -> bool {
    if mode == 1 {
        burst[candidate] < burst[best]
            || (burst[candidate] == burst[best]
                && (arrival[candidate] < arrival[best]
                    || (arrival[candidate] == arrival[best] && candidate < best)))
    } else if mode == 2 {
        remaining[candidate] < remaining[best]
            || (remaining[candidate] == remaining[best]
                && (arrival[candidate] < arrival[best]
                    || (arrival[candidate] == arrival[best] && candidate < best)))
    } else {
        priority[candidate] < priority[best]
            || (priority[candidate] == priority[best] && candidate < best)
    }
}

fn put_i64_le(output: &mut [u8], offset: usize, value: i64) {
    output[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn cpu_scheduling_algorithms(input: *const i64, length: usize,
                                                       output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 3 || length > 3 + 4 * 32 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let (mode, raw_count, quantum) = (values[0], values[1], values[2]);
    if !(0..=5).contains(&mode) || !(0..=32).contains(&raw_count) || !(1..=32).contains(&quantum) { return -1; }
    let count = raw_count as usize;
    if length != 3 + 4 * count { return -1; }

    let (mut ids, mut arrival, mut burst, mut priority, mut remaining) =
        ([0i64; 32], [0i64; 32], [0i64; 32], [0i64; 32], [0i64; 32]);
    let (mut completion, mut first_run) = ([-1i64; 32], [-1i64; 32]);
    let mut order = [0usize; 32];
    for i in 0..count {
        let base = 3 + 4 * i;
        ids[i] = values[base]; arrival[i] = values[base + 1];
        burst[i] = values[base + 2]; priority[i] = values[base + 3];
        if !(0..32).contains(&ids[i]) || !(0..=256).contains(&arrival[i])
            || !(1..=32).contains(&burst[i]) || !(-32..=32).contains(&priority[i]) { return -1; }
        if ids[..i].contains(&ids[i]) { return -1; }
        remaining[i] = burst[i]; order[i] = i;
    }
    let bytes = count * 56;
    if bytes > 0 && (output.is_null() || capacity < bytes) { return -2; }

    if mode == 0 || mode == 5 {
        for i in 1..count {
            let key = order[i];
            let mut j = i;
            while j > 0 && arrival[order[j - 1]] > arrival[key] { order[j] = order[j - 1]; j -= 1; }
            order[j] = key;
        }
    }

    let mut time = 0i64;
    if mode == 0 {
        for position in 0..count {
            let i = order[position];
            if time < arrival[i] { time = arrival[i]; }
            first_run[i] = time; time += burst[i]; completion[i] = time;
        }
    } else if mode == 1 || mode == 3 {
        let mut done = 0usize;
        while done < count {
            let mut best = count;
            for i in 0..count {
                if completion[i] >= 0 || arrival[i] > time { continue; }
                if best == count || better_choice(mode, i, best, &arrival, &burst, &remaining, &priority) { best = i; }
            }
            if best == count { time += 1; continue; }
            first_run[best] = time; time += burst[best]; completion[best] = time; done += 1;
        }
    } else if mode == 2 || mode == 4 {
        let mut done = 0usize;
        while done < count {
            let mut best = count;
            for i in 0..count {
                if remaining[i] <= 0 || arrival[i] > time { continue; }
                if best == count || better_choice(mode, i, best, &arrival, &burst, &remaining, &priority) { best = i; }
            }
            if best == count { time += 1; continue; }
            if first_run[best] < 0 { first_run[best] = time; }
            remaining[best] -= 1; time += 1;
            if remaining[best] == 0 { completion[best] = time; done += 1; }
        }
    } else {
        let (mut queue, mut head, mut tail, mut queue_size, mut next_arrival, mut done) =
            ([0usize; 64], 0usize, 0usize, 0usize, 0usize, 0usize);
        while done < count {
            while next_arrival < count && arrival[order[next_arrival]] <= time {
                queue[tail] = order[next_arrival]; next_arrival += 1; tail = (tail + 1) % 64; queue_size += 1;
            }
            if queue_size == 0 { time += 1; continue; }
            let current = queue[head]; head = (head + 1) % 64; queue_size -= 1;
            let run_for = (quantum as i64).min(remaining[current]);
            for _ in 0..run_for {
                if first_run[current] < 0 { first_run[current] = time; }
                remaining[current] -= 1; time += 1;
                while next_arrival < count && arrival[order[next_arrival]] <= time {
                    queue[tail] = order[next_arrival]; next_arrival += 1; tail = (tail + 1) % 64; queue_size += 1;
                }
            }
            if remaining[current] > 0 { queue[tail] = current; tail = (tail + 1) % 64; queue_size += 1; }
            else { completion[current] = time; done += 1; }
        }
    }

    if bytes > 0 {
        let result = std::slice::from_raw_parts_mut(output, bytes);
        for i in 0..count {
            let turnaround = completion[i] - arrival[i];
            let fields = [ids[i], arrival[i], burst[i], completion[i], turnaround,
                          turnaround - burst[i], first_run[i] - arrival[i]];
            for field in 0..7 { put_i64_le(result, i * 56 + field * 8, fields[field]); }
        }
    }
    bytes as i64
}
