module bankers_algorithm;

const usz MAX_PROCESSES = 16, MAX_RESOURCES = 8, MAX_INPUT_LENGTH = 266;

// Check whether the process/resource state has a safe completion order.
fn long bankers_algorithm_impl(long* values, usz length)
{
    if (values == null || length < 5 || length > MAX_INPUT_LENGTH) return -1;
    long process_value = values[0], resource_value = values[1];
    if (process_value < 1 || process_value > 16 || resource_value < 1 || resource_value > 8) return -1;
    usz processes = (usz)process_value, resources = (usz)resource_value;
    usz maximum_offset = 2 + resources, allocation_offset = maximum_offset + processes * resources;
    if (length != allocation_offset + processes * resources) return -1;
    long[8] work = zeroed;
    for (usz resource = 0; resource < resources; resource++) {
        long available = values[2 + resource];
        if (available < 0 || available > 100) return -1;
        work[resource] = available;
    }
    for (usz process = 0; process < processes; process++) {
        for (usz resource = 0; resource < resources; resource++) {
            usz index = process * resources + resource;
            long maximum = values[maximum_offset + index], allocation = values[allocation_offset + index];
            if (maximum < 0 || maximum > 100 || allocation < 0 || allocation > maximum) return -1;
        }
    }
    bool[16] finished = zeroed;
    usz completed = 0;
    while (completed < processes) {
        bool progress = false;
        for (usz process = 0; process < processes; process++) {
            if (finished[process]) continue;
            bool feasible = true;
            for (usz resource = 0; resource < resources; resource++) {
                usz index = process * resources + resource;
                long need = values[maximum_offset + index] - values[allocation_offset + index];
                if (need > work[resource]) { feasible = false; break; }
            }
            if (feasible) {
                for (usz resource = 0; resource < resources; resource++)
                    work[resource] += values[allocation_offset + process * resources + resource];
                finished[process] = true;
                completed++;
                progress = true;
            }
        }
        if (!progress) return 0;
    }
    return 1;
}

fn long bankers_algorithm(long* values, usz length) @export("bankers_algorithm")
{
    return bankers_algorithm_impl(values, length);
}
