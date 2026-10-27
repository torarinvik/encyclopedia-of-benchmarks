fn putI64(out: [*]u8, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |b| out[b] = @truncate(bits >> @intCast(8 * b));
}

export fn felsenstein_substitution_likelihood(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    const input = input_opt orelse return -1;
    if (length < 3 or length > 38) return -1;
    const n = input[0];
    if (n < 1 or n > 8) return -1;
    var stack = [_][2]i64{.{0,0}} ** 8;
    var sp: usize = 0; var leaves: i64 = 0; var joins: i64 = 0; var edges: i64 = 0;
    var at: usize = 1;
    while (at < length) {
        const tag = input[at]; at += 1;
        if (tag == 0) {
            if (at >= length or input[at] < 0 or input[at] > 1 or sp >= 8) return -1;
            if (input[at] == 0) {stack[sp]=.{1,0};} else {stack[sp]=.{0,1};}
            at += 1; sp += 1; leaves += 1;
        } else if (tag == 1) {
            if (at+2 > length or sp < 2 or input[at] < 0 or input[at] > 1 or input[at+1] < 0 or input[at+1] > 1) return -1;
            const lm=input[at];const rm=input[at+1];at+=2;
            const left=stack[sp-2];const right=stack[sp-1];var next=[_]i64{0,0};
            for(0..2)|parent|{const l=if(lm==0) 4*left[parent] else 3*left[parent]+left[1-parent];const r=if(rm==0) 4*right[parent] else 3*right[parent]+right[1-parent];next[parent]=l*r;}
            stack[sp-2]=next;sp-=1;joins+=1;edges+=2;
        } else {return -1;}
    }
    if(leaves!=n or joins!=n-1 or sp!=1 or edges!=2*n-2)return -1;
    const shift=29-2*edges;if(shift<0)return -1;
    const scaled=(stack[0][0]+stack[0][1])<<@intCast(shift);
    const output=output_opt orelse return -2;if(capacity<8)return -2;
    putI64(output,scaled);return 8;
}
