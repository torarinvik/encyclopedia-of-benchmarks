#include <stddef.h>
#include <stdint.h>

enum { MAX_UNIVERSE = 32, MAX_OPERATIONS = 30, MAX_LENGTH = 63 };

int64_t sparse_set_dense_array(const int64_t *input, size_t length) {
    if (input == NULL || length < 2 || length > MAX_LENGTH) return -1;
    if (input[0] < 1 || input[0] > MAX_UNIVERSE
            || input[1] < 0 || input[1] > MAX_OPERATIONS) return -1;
    const size_t universe = (size_t)input[0];
    const size_t count = (size_t)input[1];
    if (length != 2 + 2 * count) return -1;
    for (size_t i = 0; i < count; ++i) {
        const int64_t opcode = input[2 + 2 * i];
        const int64_t key = input[3 + 2 * i];
        if (opcode < 0 || opcode > 3 || key < 0 || key >= (int64_t)universe) return -1;
        if (opcode == 3 && key != 0) return -1;
    }

    int dense[MAX_UNIVERSE] = {0};
    int sparse[MAX_UNIVERSE];
    for (size_t key = 0; key < universe; ++key) sparse[key] = (int)universe;
    size_t size = 0;
    int64_t answers = 0;
    for (size_t i = 0; i < count; ++i) {
        const int opcode = (int)input[2 + 2 * i];
        const int key = (int)input[3 + 2 * i];
        const int index = sparse[key];
        const int present = index < (int)size && dense[index] == key;
        int status = 0;
        if (opcode == 0) {
            if (!present) {
                dense[size] = key;
                sparse[key] = (int)size;
                ++size;
                status = 1;
            }
        } else if (opcode == 1) {
            if (present) {
                const int last = dense[size - 1];
                dense[index] = last;
                sparse[last] = index;
                --size;
                status = 1;
            }
        } else if (opcode == 2) {
            status = present;
        } else {
            status = size != 0;
            size = 0;
        }
        answers = (answers << 1) | status;
    }
    int64_t final_mask = 0;
    for (size_t i = 0; i < size; ++i) final_mask |= INT64_C(1) << dense[i];
    return (final_mask << count) | answers;
}
