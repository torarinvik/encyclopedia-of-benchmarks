module deque_operate_all_composite;

const usz MAX_OPERATIONS = 64;
const usz TREE_BASE = 128;
const usz TREE_NODES = 256;
const long MODULUS = 998244353;

struct Affine { long a; long b; }
struct DequeState {
    Affine[TREE_NODES] tree;
    usz head;
    usz tail;
}

fn Affine identity() { return {1, 0}; }

fn Affine compose(Affine first, Affine second) {
    Affine result;
    result.a = (second.a * first.a) % MODULUS;
    result.b = (second.a * first.b + second.b) % MODULUS;
    return result;
}

fn void update(DequeState* deque, usz position, Affine value) {
    usz node = TREE_BASE + position;
    deque.tree[node] = value;
    while (node > 1) {
        node /= 2;
        deque.tree[node] = compose(deque.tree[2 * node], deque.tree[2 * node + 1]);
    }
}

fn long deque_operate_all_composite(long* values, usz length) @export("deque_operate_all_composite") {
    if (values == null || length < 1 || length > 1 + 3 * MAX_OPERATIONS) return -1;
    if (values[0] < 0 || values[0] > (long)MAX_OPERATIONS) return -1;
    usz operation_count = (usz)values[0];
    DequeState deque = zeroed;
    for (usz node = 0; node < TREE_NODES; node++) deque.tree[node] = identity();
    deque.head = 64;
    deque.tail = 64;
    usz position = 1;
    long checksum = 0;
    long query_number = 0;

    for (usz operation = 0; operation < operation_count; operation++) {
        if (position >= length) return -1;
        long opcode = values[position++];
        if (opcode == 0 || opcode == 1) {
            if (length - position < 2) return -1;
            long a = values[position++];
            long b = values[position++];
            if (a < 1 || a >= MODULUS || b < 0 || b >= MODULUS) return -1;
            Affine function = {a, b};
            if (opcode == 0) {
                if (deque.head == 0) return -1;
                deque.head--;
                update(&deque, deque.head, function);
            } else {
                if (deque.tail == TREE_BASE) return -1;
                update(&deque, deque.tail, function);
                deque.tail++;
            }
        } else if (opcode == 2 || opcode == 3) {
            if (deque.head == deque.tail) return -1;
            if (opcode == 2) {
                update(&deque, deque.head, identity());
                deque.head++;
            } else {
                deque.tail--;
                update(&deque, deque.tail, identity());
            }
        } else if (opcode == 4) {
            if (position >= length) return -1;
            long x = values[position++];
            if (x < 0 || x >= MODULUS) return -1;
            long answer = (deque.tree[1].a * x + deque.tree[1].b) % MODULUS;
            query_number++;
            checksum += query_number * (answer + 1);
        } else {
            return -1;
        }
    }
    return position == length ? checksum : -1;
}
