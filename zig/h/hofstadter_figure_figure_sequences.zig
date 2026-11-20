const MAX_TERMS: usize = 64;
const MAX_WORDS: usize = 129;

fn writeI64Le(output: []u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset+byte] = @truncate(bits >> @as(u6,@intCast(byte*8)));
}

export fn hofstadter_figure_figure_sequences(input: ?[*]const i64, length: usize,
    output: ?[*]u8, capacity: usize) i64 {
    if (input == null or length == 0 or length > 2) return -1;
    const values=input.?;
    const n_value=values[0];
    if (n_value<1 or n_value>@as(i64,@intCast(MAX_TERMS)) or length!=1) return -1;
    const n: usize=@intCast(n_value);
    var figure=[_]i64{0} ** MAX_TERMS;
    var space=[_]i64{0} ** MAX_TERMS;
    figure[0]=1; space[0]=2;
    var candidate: i64=3;
    for (1..n) |i| {
        figure[i]=figure[i-1]+space[i-1];
        var used=true;
        while (used) {
            used=false;
            for (0..(i+1)) |j| { if (figure[j]==candidate) used=true; }
            if (used) candidate+=1;
        }
        space[i]=candidate;
        candidate+=1;
    }
    const word_count=1+2*n;
    const bytes=word_count*8;
    if (output==null or capacity<bytes) return -2;
    var words=[_]i64{0} ** MAX_WORDS;
    words[0]=n_value;
    for (0..n) |i| { words[1+i]=figure[i]; words[1+n+i]=space[i]; }
    const out=output.?[0..bytes];
    for (0..word_count) |i| writeI64Le(out,i*8,words[i]);
    return @intCast(bytes);
}
