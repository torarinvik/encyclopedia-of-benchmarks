/* Check whether the process/resource state has a safe completion order. */
#include <stddef.h>
#include <stdint.h>

#define MAX_PROCESSES 16
#define MAX_RESOURCES 8
#define MAX_INPUT_LENGTH 266

int64_t bankers_algorithm(const int64_t *values, size_t length)
{
    if (values == NULL || length < 5 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t process_value = values[0], resource_value = values[1];
    if (process_value < 1 || process_value > MAX_PROCESSES ||
        resource_value < 1 || resource_value > MAX_RESOURCES) return -1;
    const size_t processes = (size_t)process_value, resources = (size_t)resource_value;
    const size_t maximum_offset = 2 + resources;
    const size_t allocation_offset = maximum_offset + processes * resources;
    if (length != allocation_offset + processes * resources) return -1;

    int64_t work[MAX_RESOURCES];
    for (size_t resource = 0; resource < resources; ++resource) {
        const int64_t available = values[2 + resource];
        if (available < 0 || available > 100) return -1;
        work[resource] = available;
    }
    for (size_t process = 0; process < processes; ++process) {
        for (size_t resource = 0; resource < resources; ++resource) {
            const size_t index = process * resources + resource;
            const int64_t maximum = values[maximum_offset + index];
            const int64_t allocation = values[allocation_offset + index];
            if (maximum < 0 || maximum > 100 || allocation < 0 || allocation > maximum) return -1;
        }
    }

    uint8_t finished[MAX_PROCESSES] = {0};
    size_t completed = 0;
    while (completed < processes) {
        int progress = 0;
        for (size_t process = 0; process < processes; ++process) {
            if (finished[process]) continue;
            int feasible = 1;
            for (size_t resource = 0; resource < resources; ++resource) {
                const size_t index = process * resources + resource;
                const int64_t need = values[maximum_offset + index] - values[allocation_offset + index];
                if (need > work[resource]) { feasible = 0; break; }
            }
            if (feasible) {
                for (size_t resource = 0; resource < resources; ++resource)
                    work[resource] += values[allocation_offset + process * resources + resource];
                finished[process] = 1;
                ++completed;
                progress = 1;
            }
        }
        if (!progress) return 0;
    }
    return 1;
}
