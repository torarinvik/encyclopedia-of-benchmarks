// Uncompiled and unexecuted two-heap slope-trick draft.
fn push(heap: *[128]i64, count: *usize, value: i64) void {
    var i = count.*; count.* += 1;
    while (i > 0) {
        const parent = (i-1)/2;
        if (heap[parent] >= value) break;
        heap[i] = heap[parent]; i = parent;
    }
    heap[i] = value;
}
fn replace(heap: *[128]i64, count: usize, value: i64) void {
    var i: usize = 0;
    while (2*i+1 < count) {
        var child = 2*i+1;
        if (child+1 < count and heap[child+1] > heap[child]) child += 1;
        if (heap[child] <= value) break;
        heap[i] = heap[child]; i = child;
    }
    heap[i] = value;
}
export fn slope_trick_lipschitz_l1(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 2 or length > 130) return -1;
    const input = input_opt.?;
    if (input[0] < 0 or input[0] > 128 or input[1] < 0 or input[1] > 100) return -1;
    const n: usize = @intCast(input[0]);
    if (length != n+2) return -1;
    for (0..n) |i| if (input[2+i] < 0 or input[2+i] > 100) { return -1; };
    var left: [128]i64 = undefined;
    var right: [128]i64 = undefined;
    var ln: usize = 0; var rn: usize = 0;
    var shift_l: i64 = 0; var shift_r: i64 = 0; var answer: i64 = 0;
    for (0..n) |i| {
        shift_l -= input[1]; shift_r += input[1];
        push(&left, &ln, input[2+i]-shift_l);
        push(&right, &rn, shift_r-input[2+i]);
        const l = left[0]+shift_l; const r = shift_r-right[0];
        if (l > r) {
            answer += l-r;
            replace(&left, ln, r-shift_l);
            replace(&right, rn, shift_r-l);
        }
    }
    return answer;
}
