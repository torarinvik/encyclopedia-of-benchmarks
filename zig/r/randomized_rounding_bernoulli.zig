const max_n: usize = 16;
const max_input: usize = 65;

export fn randomized_rounding_bernoulli(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 5 or length > max_input) return -1;
    const input = input_opt.?;
    const n64 = input[0];
    if (n64 < 1 or n64 > 16 or length != 1 + 4*@as(usize, @intCast(n64))) return -1;
    const n: usize = @intCast(n64);
    var staged: [max_n]u8 = @splat(0);
    for (0..n) |i| {
        const x_num=input[1+4*i]; const x_den=input[2+4*i];
        const u_num=input[3+4*i]; const u_den=input[4+4*i];
        if (x_den<1 or x_den>32 or x_num<0 or x_num>x_den or
            u_den<1 or u_den>32 or u_num<0 or u_num>=u_den) return -1;
        staged[i] = if (u_num*x_den < x_num*u_den) 1 else 0;
    }
    if (output_opt == null or capacity < n) return -2;
    const output = output_opt.?;
    for (0..n) |i| output[i]=staged[i];
    return @intCast(n);
}
