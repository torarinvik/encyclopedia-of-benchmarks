export fn imply_gate(left: u64, right: u64) i64 {
    if (left > 1 or right > 1) return -1;
    return if (left == 0 or right == 1) 1 else 0;
}
