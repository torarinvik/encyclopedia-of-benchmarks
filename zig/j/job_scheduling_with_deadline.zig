const MAX_JOBS: usize = 128;
const MAX_INPUT_LENGTH: usize = 1 + 4 * MAX_JOBS;
const PACK_BASE: i64 = 4_294_967_296;

export fn job_scheduling_with_deadline(packed: ?[*]const i64, length: usize) i64 {
    if (length < 1 or length > MAX_INPUT_LENGTH) return -1;
    const input = packed orelse return -1;
    const count_value = input[0];
    if (count_value < 0 or count_value > 128 or
        length != 1 + @as(usize, @intCast(count_value)) * 4) return -1;
    const count: usize = @intCast(count_value);

    var ids = [_]i64{0} ** MAX_JOBS;
    var arrivals = [_]i64{0} ** MAX_JOBS;
    var deadlines = [_]i64{0} ** MAX_JOBS;
    var profits = [_]i64{0} ** MAX_JOBS;
    var max_deadline: i64 = 0;
    for (0..count) |i| {
        const base = 1 + i * 4;
        ids[i] = input[base];
        arrivals[i] = input[base + 1];
        deadlines[i] = input[base + 2];
        profits[i] = input[base + 3];
        if (ids[i] < 0 or ids[i] > 2_147_483_647 or
            arrivals[i] < 1 or arrivals[i] > 32 or
            deadlines[i] < 1 or deadlines[i] > 32 or
            profits[i] < -1_000_000 or profits[i] > 1_000_000) return -1;
        for (0..i) |previous| if (ids[previous] == ids[i]) return -1;
        max_deadline = @max(max_deadline, deadlines[i]);
    }

    // Stable insertion sort preserves input order for equal profits.
    for (1..count) |i| {
        const key_id = ids[i];
        const key_arrival = arrivals[i];
        const key_deadline = deadlines[i];
        const key_profit = profits[i];
        var position = i;
        while (position > 0 and profits[position - 1] < key_profit) {
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

    var occupied = [_]bool{false} ** 32;
    var scheduled: i64 = 0;
    var total_profit: i64 = 0;
    for (0..count) |i| {
        if (arrivals[i] > deadlines[i]) continue;
        const last_slot = @min(deadlines[i] - 1, max_deadline - 1);
        var slot = last_slot;
        while (slot >= arrivals[i] - 1) : (slot -= 1) {
            const index: usize = @intCast(slot);
            if (!occupied[index]) {
                occupied[index] = true;
                scheduled += 1;
                total_profit += profits[i];
                break;
            }
        }
    }

    const low_word = if (total_profit < 0) total_profit + PACK_BASE else total_profit;
    return scheduled * PACK_BASE + low_word;
}
