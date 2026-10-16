/// Return a zero-based station index that completes the circuit, or -1.
pub export fn gas_station(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 1) return -2;
    const n64=input[0]; if (n64 < 0 or n64 > 128) return -2;
    const n: usize=@intCast(n64);
    if (length != 2*n+1) return -2;
    const values=input[1..length];
    for (values) |v| { if (v < 0 or v > 1_000_000) return -2; }
    var total:i64=0; var current:i64=0; var start:usize=0;
    for (0..n) |i| {
        const net=values[i]-values[n+i]; total+=net; current+=net;
        if (current<0) { start=i+1; current=0; }
    }
    if (total<0) return -1;
    return @intCast(start);
}
