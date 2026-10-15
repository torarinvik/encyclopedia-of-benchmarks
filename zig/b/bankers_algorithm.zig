const MAX_PROCESSES: usize = 16;
const MAX_RESOURCES: usize = 8;

/// Check whether the process/resource state has a safe completion order.
export fn bankers_algorithm(values: [*]const i64, length: usize) i64 {
    if (length < 5 or length > 266) return -1;
    const input = values[0..length];
    const process_value = input[0];
    const resource_value = input[1];
    if (process_value < 1 or process_value > 16 or
        resource_value < 1 or resource_value > 8) return -1;
    const processes: usize = @intCast(process_value);
    const resources: usize = @intCast(resource_value);
    const maximum_offset = 2 + resources;
    const allocation_offset = maximum_offset + processes * resources;
    if (length != allocation_offset + processes * resources) return -1;
    var work = [_]i64{0} ** MAX_RESOURCES;
    for (0..resources) |resource| {
        const available = input[2 + resource];
        if (available < 0 or available > 100) return -1;
        work[resource] = available;
    }
    for (0..processes) |process| {
        for (0..resources) |resource| {
            const index = process * resources + resource;
            const maximum = input[maximum_offset + index];
            const allocation = input[allocation_offset + index];
            if (maximum < 0 or maximum > 100 or allocation < 0 or allocation > maximum) return -1;
        }
    }

    var finished = [_]bool{false} ** MAX_PROCESSES;
    var completed: usize = 0;
    while (completed < processes) {
        var progress = false;
        for (0..processes) |process| {
            if (finished[process]) continue;
            var feasible = true;
            for (0..resources) |resource| {
                const index = process * resources + resource;
                if (input[maximum_offset + index] - input[allocation_offset + index] > work[resource]) {
                    feasible = false;
                    break;
                }
            }
            if (feasible) {
                for (0..resources) |resource| {
                    work[resource] += input[allocation_offset + process * resources + resource];
                }
                finished[process] = true;
                completed += 1;
                progress = true;
            }
        }
        if (!progress) return 0;
    }
    return 1;
}
