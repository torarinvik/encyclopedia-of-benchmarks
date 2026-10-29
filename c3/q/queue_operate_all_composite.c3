module queue_operate_all_composite;

const usz MAX_OPERATIONS = 64;
const usz MAX_INPUT_LENGTH = 1 + 3 * MAX_OPERATIONS;
const long MODULUS = 998244353;

struct Affine { long a; long b; }
struct QueueState {
    Affine[MAX_OPERATIONS] back_functions;
    Affine[MAX_OPERATIONS] back_aggregates;
    Affine[MAX_OPERATIONS] front_aggregates;
    usz back_size;
    usz front_size;
}

fn Affine compose(Affine first, Affine second) {
    Affine result;
    result.a = (second.a * first.a) % MODULUS;
    result.b = (second.a * first.b + second.b) % MODULUS;
    return result;
}

fn void push_back(QueueState* queue, long a, long b) {
    Affine function = {a, b};
    queue.back_functions[queue.back_size] = function;
    queue.back_aggregates[queue.back_size] = queue.back_size == 0
        ? function : compose(queue.back_aggregates[queue.back_size - 1], function);
    queue.back_size++;
}

fn void transfer(QueueState* queue) {
    while (queue.back_size > 0) {
        queue.back_size--;
        Affine function = queue.back_functions[queue.back_size];
        queue.front_aggregates[queue.front_size] = queue.front_size == 0
            ? function : compose(function, queue.front_aggregates[queue.front_size - 1]);
        queue.front_size++;
    }
}

fn bool pop_front(QueueState* queue) {
    if (queue.front_size == 0) transfer(queue);
    if (queue.front_size == 0) return false;
    queue.front_size--;
    return true;
}

fn Affine aggregate(QueueState* queue) {
    Affine result = {1, 0};
    if (queue.front_size > 0) result = queue.front_aggregates[queue.front_size - 1];
    if (queue.back_size > 0) {
        result = queue.front_size > 0
            ? compose(result, queue.back_aggregates[queue.back_size - 1])
            : queue.back_aggregates[queue.back_size - 1];
    }
    return result;
}

fn long queue_operate_all_composite(long* values, usz length) @export("queue_operate_all_composite") {
    if (values == null || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    long operation_value = values[0];
    if (operation_value < 0 || operation_value > (long)MAX_OPERATIONS) return -1;
    usz operation_count = (usz)operation_value;

    QueueState queue = zeroed;
    usz position = 1;
    long checksum = 0;
    long query_number = 0;
    for (usz operation = 0; operation < operation_count; operation++) {
        if (position >= length) return -1;
        long opcode = values[position];
        position++;
        if (opcode == 0) {
            if (length - position < 2) return -1;
            long a = values[position];
            long b = values[position + 1];
            position += 2;
            if (a < 1 || a >= MODULUS || b < 0 || b >= MODULUS) return -1;
            push_back(&queue, a, b);
        } else if (opcode == 1) {
            if (!pop_front(&queue)) return -1;
        } else if (opcode == 2) {
            if (position >= length) return -1;
            long x = values[position];
            position++;
            if (x < 0 || x >= MODULUS) return -1;
            Affine function = aggregate(&queue);
            long answer = (function.a * x + function.b) % MODULUS;
            query_number++;
            checksum += query_number * (answer + 1);
        } else {
            return -1;
        }
    }
    return position == length ? checksum : -1;
}
