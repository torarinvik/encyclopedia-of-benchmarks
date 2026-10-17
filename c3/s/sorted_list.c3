module sorted_list;

const long MAX_VALUE = 1_000_000;
const usz MAX_PARSEABLE_INPUT_LENGTH = 1025;
const long CHECKSUM_OFFSET = 1_000_000;

fn usz sorted_list_lower_bound(long* values, usz size, long target) {
    usz left = 0;
    usz right = size;
    while (left < right) {
        usz middle = left + (right - left) / 2;
        if (values[middle] < target) left = middle + 1;
        else right = middle;
    }
    return left;
}

fn long sorted_list_benchmark(long* input, usz length) @export("sorted_list_benchmark") {
    if (length > MAX_PARSEABLE_INPUT_LENGTH || (length > 0 && input == null) || (length & 1) != 0) return -1;
    usz operation_count = length / 2;
    if (operation_count > 512) return -1;

    long items[256];
    usz size = 0;
    long checksum = 0;
    for (usz operation = 0; operation < operation_count; ++operation) {
        long opcode = input[2 * operation];
        long payload = input[2 * operation + 1];
        long observed = 0;
        bool has_observation = true;

        if (opcode == 0) {
            if (payload < 0 || payload > MAX_VALUE || size >= 256) return -1;
            usz position = sorted_list_lower_bound(items, size, payload);
            for (usz index = size; index > position; --index) items[index] = items[index - 1];
            items[position] = payload;
            size += 1;
            has_observation = false;
        } else if (opcode == 1 || opcode == 2) {
            if (payload < 0 || payload > MAX_VALUE) return -1;
            usz position = sorted_list_lower_bound(items, size, payload);
            bool found = position < size && items[position] == payload;
            observed = found ? 1 : 0;
            if (opcode == 2 && found) {
                for (usz index = position; index + 1 < size; ++index) items[index] = items[index + 1];
                size -= 1;
            }
        } else if (opcode == 3) {
            if (payload != 0) return -1;
            observed = (long)size;
        } else if (opcode == 4) {
            if (payload < 0 || (usz)payload >= size) return -1;
            observed = items[(usz)payload];
        } else if (opcode == 5) {
            if (payload != 0) return -1;
            size = 0;
            has_observation = false;
        } else {
            return -1;
        }

        if (has_observation) checksum += (long)(operation + 1) * (observed + CHECKSUM_OFFSET);
    }

    for (usz index = 0; index < size; ++index)
        checksum += (long)(operation_count + index + 1) * (items[index] + CHECKSUM_OFFSET);
    return checksum;
}
