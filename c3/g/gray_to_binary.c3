module gray_to_binary;

fn long gray_to_binary(long gray) @export("gray_to_binary") {
    if (gray < 0) return -1;
    long binary = gray;
    gray = gray >> 1;
    while (gray != 0) {
        binary ^= gray;
        gray = gray >> 1;
    }
    return binary;
}
