module count_singly_linked_list_recursion;

const usz MAX_NODES = 64;
const long MIN_PAYLOAD = -2147483648L;
const long MAX_PAYLOAD = 2147483647L;

fn long count_recursive(long* input, usz index, usz remaining) {
    if (remaining == 0) return 0;
    long payload = input[index];
    if (payload < MIN_PAYLOAD || payload > MAX_PAYLOAD) return -1;
    long tail_count = count_recursive(input, index + 1, remaining - 1);
    if (tail_count < 0) return -1;
    return 1 + tail_count;
}

// Recursively count a finite singly linked chain represented in node order.
fn long count_singly_linked_list_recursion(long* input, usz length) @export("count_singly_linked_list_recursion") {
    if (input == null || length < 1 || input[0] < 0 || input[0] > (long)MAX_NODES) return -1;
    usz count = (usz)input[0];
    if (length != count + 1) return -1;
    return count_recursive(input, 1, count);
}
