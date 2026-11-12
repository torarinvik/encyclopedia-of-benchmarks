module point_set_range_sort_range_composite;

const long MODULUS = 998244353;
const usz MAX_LENGTH = 210;
const long MAX_PRIORITY = 1000000000;

struct Record { long priority; long a; long b; }

fn long point_set_range_sort_range_composite(long* input, usz length)
    @export("point_set_range_sort_range_composite") {
    if (input == null || length < 2 || length > MAX_LENGTH) return -1;
    long n_value = input[0], q_value = input[1];
    if (n_value < 1 || n_value > 16 || q_value < 1 || q_value > 32) return -1;
    usz n = (usz)n_value, q = (usz)q_value;
    if (length < 2 + 3 * n) return -1;
    Record[16] records = {};
    long[48] seen = {};
    usz seen_count = 0, cursor = 2;
    for (usz i = 0; i < n; i++) {
        long p = input[cursor], a = input[cursor + 1], b = input[cursor + 2];
        cursor += 3;
        if (p < 0 || p > MAX_PRIORITY || a < 1 || a >= MODULUS || b < 0 || b >= MODULUS) return -1;
        for (usz j = 0; j < seen_count; j++) if (seen[j] == p) return -1;
        seen[seen_count++] = p;
        records[i] = {p, a, b};
    }
    long checksum = 0, query_number = 0;
    for (usz operation = 0; operation < q; operation++) {
        if (cursor >= length) return -1;
        long opcode = input[cursor++];
        if (opcode == 0) {
            if (length - cursor < 4) return -1;
            long index = input[cursor], p = input[cursor + 1], a = input[cursor + 2], b = input[cursor + 3];
            cursor += 4;
            if (index < 0 || index >= n_value || p < 0 || p > MAX_PRIORITY || a < 1 || a >= MODULUS || b < 0 || b >= MODULUS) return -1;
            for (usz j = 0; j < seen_count; j++) if (seen[j] == p) return -1;
            seen[seen_count++] = p;
            records[(usz)index] = {p, a, b};
        } else if (opcode == 1) {
            if (length - cursor < 3) return -1;
            long left = input[cursor], right = input[cursor + 1], x = input[cursor + 2];
            cursor += 3;
            if (left < 0 || left >= right || right > n_value || x < 0 || x >= MODULUS) return -1;
            long answer = x;
            for (usz i = (usz)left; i < (usz)right; i++) answer = (records[i].a * answer + records[i].b) % MODULUS;
            query_number++;
            checksum = (checksum + query_number * answer) % MODULUS;
        } else if (opcode == 2 || opcode == 3) {
            if (length - cursor < 2) return -1;
            long left = input[cursor], right = input[cursor + 1];
            cursor += 2;
            if (left < 0 || left >= right || right > n_value) return -1;
            for (usz i = (usz)left + 1; i < (usz)right; i++) {
                Record item = records[i];
                usz j = i;
                while (j > (usz)left && ((opcode == 2 && records[j - 1].priority > item.priority) || (opcode == 3 && records[j - 1].priority < item.priority))) {
                    records[j] = records[j - 1];
                    j--;
                }
                records[j] = item;
            }
        } else return -1;
    }
    return cursor == length ? checksum : -1;
}
