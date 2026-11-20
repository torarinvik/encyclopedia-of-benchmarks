module slide_window_aggregation_deque;

const usz MAX_OPERATIONS = 32;
const usz MAX_INPUT_LENGTH = 162;
const long MODULUS = 97;

struct Matrix { long a; long b; long c; long d; }

fn Matrix identity() { return Matrix{1, 0, 0, 1}; }

fn Matrix multiply(Matrix x, Matrix y) {
    return Matrix{
        (x.a * y.a + x.b * y.c) % MODULUS,
        (x.a * y.b + x.b * y.d) % MODULUS,
        (x.c * y.a + x.d * y.c) % MODULUS,
        (x.c * y.b + x.d * y.d) % MODULUS
    };
}

fn long pack(Matrix value) {
    return value.a + MODULUS * value.b + MODULUS * MODULUS * value.c +
        MODULUS * MODULUS * MODULUS * value.d;
}

fn usz push_front(Matrix* items, Matrix* aggregates, usz count, Matrix value) {
    items[count] = value;
    aggregates[count] = count == 0 ? value : multiply(value, aggregates[count - 1]);
    return count + 1;
}

fn usz push_back(Matrix* items, Matrix* aggregates, usz count, Matrix value) {
    items[count] = value;
    aggregates[count] = count == 0 ? value : multiply(aggregates[count - 1], value);
    return count + 1;
}

fn long slide_window_aggregation_deque(long* input, usz length) @export("slide_window_aggregation_deque") {
    if (input == null || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    long operation_count_value = input[0];
    if (operation_count_value < 0 || operation_count_value > (long)MAX_OPERATIONS) return -1;
    usz operation_count = (usz)operation_count_value;
    Matrix[MAX_OPERATIONS] front;
    Matrix[MAX_OPERATIONS] front_aggregate;
    Matrix[MAX_OPERATIONS] back;
    Matrix[MAX_OPERATIONS] back_aggregate;
    Matrix[MAX_OPERATIONS] temporary;
    usz front_count = 0, back_count = 0, cursor = 1, query_ordinal = 0;
    long checksum = 0;
    for (usz operation = 0; operation < operation_count; operation++) {
        if (cursor >= length) return -1;
        long opcode = input[cursor];
        cursor++;
        if (opcode == 0 || opcode == 1) {
            if (cursor + 4 > length) return -1;
            Matrix value;
            value.a = input[cursor]; value.b = input[cursor + 1];
            value.c = input[cursor + 2]; value.d = input[cursor + 3];
            for (usz j = 0; j < 4; j++) {
                if (input[cursor + j] < 0 || input[cursor + j] >= MODULUS) return -1;
            }
            cursor += 4;
            if (opcode == 0) front_count = push_front(&front[0], &front_aggregate[0], front_count, value);
            else back_count = push_back(&back[0], &back_aggregate[0], back_count, value);
        } else if (opcode == 2 || opcode == 3) {
            if (front_count + back_count == 0) return -1;
            if (opcode == 2) {
                if (front_count == 0) {
                    usz total = front_count + back_count;
                    usz front_size = total / 2 + total % 2;
                    for (usz i = 0; i < back_count; i++) temporary[i] = back[i];
                    front_count = 0; back_count = 0;
                    for (usz i = front_size; i > 0; i--) front_count = push_front(&front[0], &front_aggregate[0], front_count, temporary[i - 1]);
                    for (usz i = front_size; i < total; i++) back_count = push_back(&back[0], &back_aggregate[0], back_count, temporary[i]);
                }
                front_count--;
            } else {
                if (back_count == 0) {
                    usz total = front_count + back_count;
                    usz front_size = total / 2;
                    for (usz i = 0; i < front_count; i++) temporary[i] = front[front_count - 1 - i];
                    front_count = 0; back_count = 0;
                    for (usz i = front_size; i > 0; i--) front_count = push_front(&front[0], &front_aggregate[0], front_count, temporary[i - 1]);
                    for (usz i = front_size; i < total; i++) back_count = push_back(&back[0], &back_aggregate[0], back_count, temporary[i]);
                }
                back_count--;
            }
        } else if (opcode == 4) {
            Matrix left = front_count == 0 ? identity() : front_aggregate[front_count - 1];
            Matrix right = back_count == 0 ? identity() : back_aggregate[back_count - 1];
            query_ordinal++;
            checksum += (long)query_ordinal * (pack(multiply(left, right)) + 1);
        } else return -1;
    }
    return cursor == length ? checksum : -1;
}
