// Independently authored draft; not compiled or run.
export fn circle_line_intersection_symbolic(input: [*c]const i64, length: usize,
    output: [*c]u8, capacity: usize) i64 {
    if (input == null or length != 6) return -1;
    for (0..6) |i| {
        if (input[i] < -1000 or input[i] > 1000) return -1;
    }
    const x=input[0]; const y=input[1]; const r=input[2];
    const a=input[3]; const b=input[4]; const c=input[5];
    if (r < 1 or (a == 0 and b == 0)) return -1;
    const d=a*a+b*b; const q=a*x+b*y+c; const h=r*r*d-q*q;
    const words = [7]i64{if (h < 0) 0 else if (h == 0) 1 else 2, x*d-a*q, y*d-b*q, d, -b, a, h};
    const count: usize = if (h < 0) 1 else 7;
    const needed = 8*count;
    if (output == null or capacity < needed) return -2;
    for (0..count) |i| {
        const bits: u64 = @bitCast(words[i]);
        for (0..8) |j| output[8*i+j] = @truncate(bits >> @as(u6, @intCast(8*j)));
    }
    return @intCast(needed);
}
