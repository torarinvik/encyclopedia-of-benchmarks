module sorted_table;

const long MIN_KEY = -1_000_000;
const long MAX_KEY = 1_000_000;
const long KEY_OFFSET = 1_000_001;
const long HASH_MODULUS = 1_000_000_007;
const usz MAX_PARSEABLE_INPUT_LENGTH = 899;

fn usz sorted_table_lower_bound(long* values, usz size, long target) {
    usz left = 0;
    usz right = size;
    while (left < right) {
        usz middle = left + (right - left) / 2;
        if (values[middle] < target) left = middle + 1;
        else right = middle;
    }
    return left;
}

fn usz sorted_table_upper_bound(long* values, usz size, long target) {
    usz left = 0;
    usz right = size;
    while (left < right) {
        usz middle = left + (right - left) / 2;
        if (values[middle] <= target) left = middle + 1;
        else right = middle;
    }
    return left;
}

fn long sorted_table_key_code(long key) { return key + KEY_OFFSET; }

fn long sorted_table_sequence_code(long* values, usz first, usz last, bool descending) {
    usz count = last - first;
    long hash = 0;
    if (descending) {
        while (last > first) {
            last -= 1;
            hash = (31 * hash + sorted_table_key_code(values[last])) % HASH_MODULUS;
        }
    } else {
        for (usz index = first; index < last; ++index)
            hash = (31 * hash + sorted_table_key_code(values[index])) % HASH_MODULUS;
    }
    return (long)count * HASH_MODULUS + hash;
}

fn long sorted_table_benchmark(long* input, usz length) @export("sorted_table_benchmark") {
    if (length > MAX_PARSEABLE_INPUT_LENGTH || (length > 0 && input == null) || length < 2) return -1;
    if (input[0] < 0 || input[0] > 128) return -1;
    usz initial_count = (usz)input[0];
    usz operation_count_index = initial_count + 1;
    if (operation_count_index >= length) return -1;
    long operation_count_value = input[operation_count_index];
    if (operation_count_value < 0 || operation_count_value > 256) return -1;
    usz operation_count = (usz)operation_count_value;
    usz operations_start = operation_count_index + 1;
    if (length != operations_start + 3 * operation_count) return -1;

    long items[256];
    for (usz index = 0; index < initial_count; ++index) {
        long key = input[index + 1];
        if (key < MIN_KEY || key > MAX_KEY || (index > 0 && items[index - 1] >= key)) return -1;
        items[index] = key;
    }
    usz size = initial_count;
    long checksum = 0;

    for (usz operation = 0; operation < operation_count; ++operation) {
        usz offset = operations_start + 3 * operation;
        long opcode = input[offset];
        long a = input[offset + 1];
        long b = input[offset + 2];
        bool has_observation = true;
        long observed = 0;
        usz position = 0;

        if (opcode == 0 || opcode == 1 || opcode == 4 || opcode == 5 || opcode == 7) {
            if (b != 0 || a < MIN_KEY || a > MAX_KEY) return -1;
            position = sorted_table_lower_bound(items, size, a);
            bool found = position < size && items[position] == a;
            if (opcode == 0) observed = found ? sorted_table_key_code(a) : 0;
            else if (opcode == 1) observed = found ? 1 : 0;
            else if (opcode == 4) {
                if (found) position += 1;
                if (position < size) observed = sorted_table_key_code(items[position]);
            } else if (opcode == 5) {
                if (position > 0) observed = sorted_table_key_code(items[position - 1]);
            } else if (found) {
                observed = sorted_table_key_code(a);
                for (usz index = position; index + 1 < size; ++index) items[index] = items[index + 1];
                size -= 1;
            }
        } else if (opcode == 2 || opcode == 3) {
            if (a != 0 || b != 0) return -1;
            if (size > 0) observed = sorted_table_key_code(items[opcode == 2 ? 0 : size - 1]);
        } else if (opcode == 6) {
            if (a < MIN_KEY || a > MAX_KEY || (b != 0 && b != 1)) return -1;
            position = sorted_table_lower_bound(items, size, a);
            bool found = position < size && items[position] == a;
            if (found) observed = sorted_table_key_code(a);
            else {
                if (size >= 256) return -1;
                for (usz index = size; index > position; --index) items[index] = items[index - 1];
                items[position] = a;
                size += 1;
            }
        } else if (opcode == 8 || opcode == 9) {
            if (a < MIN_KEY || a > MAX_KEY || b < MIN_KEY || b > MAX_KEY) return -1;
            if (a <= b) {
                usz first = sorted_table_lower_bound(items, size, a);
                usz last = sorted_table_upper_bound(items, size, b);
                observed = sorted_table_sequence_code(items, first, last, opcode == 9);
            }
        } else if (opcode == 10 || opcode == 11) {
            if (a != 0 || b != 0) return -1;
            observed = sorted_table_sequence_code(items, 0, size, opcode == 11);
        } else if (opcode == 12) {
            if (a != 0 || b != 0) return -1;
            observed = size == 0 ? 1 : 0;
        } else if (opcode == 13) {
            if (a != 0 || b != 0) return -1;
            size = 0;
            has_observation = false;
        } else {
            return -1;
        }

        if (has_observation) checksum += (long)(operation + 1) * (observed + 1);
    }

    for (usz index = 0; index < size; ++index)
        checksum += (long)(operation_count + index + 1) * sorted_table_key_code(items[index]);
    return checksum;
}
