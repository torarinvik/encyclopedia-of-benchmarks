/* Check whether the process/resource state has a safe completion order. */
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t bankers_algorithm(const std::int64_t *values,
                                           std::size_t length) noexcept
{
    constexpr std::size_t max_processes = 16, max_resources = 8, max_input_length = 266;
    if (values == nullptr || length < 5 || length > max_input_length) return -1;
    const std::int64_t process_value = values[0], resource_value = values[1];
    if (process_value < 1 || process_value > static_cast<std::int64_t>(max_processes) ||
        resource_value < 1 || resource_value > static_cast<std::int64_t>(max_resources)) return -1;
    const std::size_t processes = static_cast<std::size_t>(process_value);
    const std::size_t resources = static_cast<std::size_t>(resource_value);
    const std::size_t maximum_offset = 2 + resources;
    const std::size_t allocation_offset = maximum_offset + processes * resources;
    if (length != allocation_offset + processes * resources) return -1;

    std::int64_t work[max_resources]{};
    for (std::size_t resource = 0; resource < resources; ++resource) {
        const auto available = values[2 + resource];
        if (available < 0 || available > 100) return -1;
        work[resource] = available;
    }
    for (std::size_t process = 0; process < processes; ++process) {
        for (std::size_t resource = 0; resource < resources; ++resource) {
            const auto index = process * resources + resource;
            const auto maximum = values[maximum_offset + index];
            const auto allocation = values[allocation_offset + index];
            if (maximum < 0 || maximum > 100 || allocation < 0 || allocation > maximum) return -1;
        }
    }

    bool finished[max_processes]{};
    std::size_t completed = 0;
    while (completed < processes) {
        bool progress = false;
        for (std::size_t process = 0; process < processes; ++process) {
            if (finished[process]) continue;
            bool feasible = true;
            for (std::size_t resource = 0; resource < resources; ++resource) {
                const auto index = process * resources + resource;
                if (values[maximum_offset + index] - values[allocation_offset + index] > work[resource]) {
                    feasible = false;
                    break;
                }
            }
            if (feasible) {
                for (std::size_t resource = 0; resource < resources; ++resource)
                    work[resource] += values[allocation_offset + process * resources + resource];
                finished[process] = true;
                ++completed;
                progress = true;
            }
        }
        if (!progress) return 0;
    }
    return 1;
}
