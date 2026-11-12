#include <stddef.h>
#include <stdint.h>

enum { MAX_OPERATIONS = 64, TREE_BASE = 128, TREE_NODES = 256 };
static const int64_t MODULUS = INT64_C(998244353);

typedef struct {
    int64_t a;
    int64_t b;
} Affine;

static Affine identity(void)
{
    return (Affine){1, 0};
}

static Affine compose(Affine first, Affine second)
{
    return (Affine){
        (second.a * first.a) % MODULUS,
        (second.a * first.b + second.b) % MODULUS,
    };
}

static void update(Affine tree[TREE_NODES], size_t position, Affine value)
{
    size_t node = (size_t)TREE_BASE + position;
    tree[node] = value;
    while (node > 1) {
        node >>= 1;
        tree[node] = compose(tree[node * 2], tree[node * 2 + 1]);
    }
}

int64_t deque_operate_all_composite(const int64_t *values, size_t length)
{
    if (values == NULL || length < 1 || length > 1 + 3 * MAX_OPERATIONS) return -1;
    if (values[0] < 0 || values[0] > MAX_OPERATIONS) return -1;
    const size_t operation_count = (size_t)values[0];
    Affine tree[TREE_NODES];
    for (size_t node = 0; node < TREE_NODES; ++node) tree[node] = identity();

    size_t head = 64;
    size_t tail = 64;
    size_t position = 1;
    int64_t checksum = 0;
    int64_t query_number = 0;
    for (size_t operation = 0; operation < operation_count; ++operation) {
        if (position >= length) return -1;
        const int64_t opcode = values[position++];
        if (opcode == 0 || opcode == 1) {
            if (length - position < 2) return -1;
            const int64_t a = values[position++];
            const int64_t b = values[position++];
            if (a < 1 || a >= MODULUS || b < 0 || b >= MODULUS) return -1;
            const Affine function = {a, b};
            if (opcode == 0) {
                if (head == 0) return -1;
                --head;
                update(tree, head, function);
            } else {
                if (tail == TREE_BASE) return -1;
                update(tree, tail++, function);
            }
        } else if (opcode == 2 || opcode == 3) {
            if (head == tail) return -1;
            if (opcode == 2) update(tree, head++, identity());
            else update(tree, --tail, identity());
        } else if (opcode == 4) {
            if (position >= length) return -1;
            const int64_t x = values[position++];
            if (x < 0 || x >= MODULUS) return -1;
            const Affine function = tree[1];
            const int64_t answer = (function.a * x + function.b) % MODULUS;
            ++query_number;
            checksum += query_number * (answer + 1);
        } else {
            return -1;
        }
    }
    return position == length ? checksum : -1;
}
