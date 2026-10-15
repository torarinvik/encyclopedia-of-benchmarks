module path_sum;

fn bool path_has_sum(long* input, usz node, long sum, long target)
{
    usz base = 2 + 3 * node;
    sum += input[base];
    long left = input[base + 1];
    long right = input[base + 2];
    if (left == -1 && right == -1) return sum == target;
    return (left != -1 && path_has_sum(input, (usz)left, sum, target)) ||
           (right != -1 && path_has_sum(input, (usz)right, sum, target));
}

// Check whether a root-to-leaf path has the requested sum.
fn long path_sum(long* input, usz length) @export("path_sum")
{
    if (length < 2 || input[1] < 0 || input[1] > 63) return -1;
    usz count = (usz)input[1];
    if (length != 2 + 3 * count) return -1;
    if (count == 0) return 0;
    for (usz index = 0; index < count; index++) {
        usz base = 2 + 3 * index;
        if (input[base] < -2147483648 || input[base] > 2147483647) return -1;
        for (usz edge = 1; edge <= 2; edge++) {
            if (input[base + edge] < -1 || input[base + edge] >= (long)count) return -1;
        }
    }
    bool[63] seen;
    usz[63] stack;
    for (usz index = 0; index < 63; index++) { seen[index] = false; stack[index] = 0; }
    usz top = 1;
    usz visited = 0;
    stack[0] = 0;
    while (top > 0) {
        top--;
        usz node = stack[top];
        if (seen[node]) return -1;
        seen[node] = true;
        visited++;
        usz base = 2 + 3 * node;
        long left = input[base + 1];
        long right = input[base + 2];
        if (left != -1) { stack[top] = (usz)left; top++; }
        if (right != -1) { stack[top] = (usz)right; top++; }
    }
    if (visited != count) return -1;
    return path_has_sum(input, 0, 0, input[0]) ? 1 : 0;
}
