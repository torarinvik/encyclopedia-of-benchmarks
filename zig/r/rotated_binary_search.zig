export fn rotated_binary_search(input: ?[*]const i64, length: usize) i64 {
    if (input == null or length < 2) return -2;
    const a = input.?[0..length];
    if (a[0] < 0 or a[0] > 256) return -2;
    const n: usize = @intCast(a[0]);
    if (length != n + 2) return -2;
    if (n == 0) return -1;
    const key = a[n + 1];
    if (key < -2_147_483_648 or key > 2_147_483_647) return -2;
    var drops: usize = 0;
    for (0..n) |i| {
        if (a[i + 1] < -2_147_483_648 or a[i + 1] > 2_147_483_647) return -2;
        if (i > 0 and a[i] > a[i + 1]) drops += 1;
    }
    if (drops > 1 or (drops == 1 and a[n] > a[1])) return -2;
    var left: usize = 0;
    var right = n - 1;
    while (left <= right) {
        const middle = left + (right - left) / 2;
        const mid = a[middle + 1];
        if (key == mid) return @intCast(middle);
        if (a[left + 1] == mid and mid == a[right + 1]) {
            left += 1;
            if (right == 0) break;
            right -= 1;
            continue;
        }
        if (a[left + 1] <= mid) {
            if (a[left + 1] <= key and key < mid) {
                if (middle == 0) break;
                right = middle - 1;
            } else left = middle + 1;
        } else if (mid < key and key <= a[right + 1]) left = middle + 1
        else {
            if (middle == 0) break;
            right = middle - 1;
        }
    }
    return -1;
}
