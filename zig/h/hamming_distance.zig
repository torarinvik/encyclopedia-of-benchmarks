export fn hamming_distance(left: u64, right: u64) i64 {
    return @popCount(left ^ right);
}
