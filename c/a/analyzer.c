#include <stddef.h>
#include <stdint.h>

#define MAX_EVENTS 64
#define MAX_EPOCH 15
#define MAX_ADDRESS 255

int64_t analyzer(const int64_t *input, size_t length) {
    if (input == NULL || length < 1 || length > 1 + 3 * MAX_EVENTS + 1) return -1;
    const int64_t count_value = input[0];
    if (count_value < 0 || count_value > MAX_EVENTS) return -1;
    const size_t count = (size_t)count_value;
    if (length != 1 + 3 * count) return -1;
    int64_t latest_writer[MAX_ADDRESS + 1];
    for (size_t address = 0; address <= MAX_ADDRESS; ++address) latest_writer[address] = -1;
    int64_t conflicts = 0, previous_epoch = 0;
    for (size_t event = 0; event < count; ++event) {
        const size_t base = 1 + 3 * event;
        const int64_t epoch = input[base], opcode = input[base + 1], address_value = input[base + 2];
        if (epoch < previous_epoch || epoch < 0 || epoch > MAX_EPOCH
                || (opcode != 0 && opcode != 1) || address_value < 0 || address_value > MAX_ADDRESS) return -1;
        previous_epoch = epoch;
        const size_t address = (size_t)address_value;
        if (opcode == 0) {
            latest_writer[address] = (int64_t)event;
        } else {
            for (size_t prior = 0; prior < event; ++prior) {
                const size_t prior_base = 1 + 3 * prior;
                if (input[prior_base] < epoch && input[prior_base + 1] == 0
                        && input[prior_base + 2] == address_value
                        && latest_writer[address] == (int64_t)prior) {
                    ++conflicts;
                }
            }
        }
    }
    return conflicts;
}
