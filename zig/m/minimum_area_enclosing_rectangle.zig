fn projection(input: [*]const i64, index: usize, dx: i64, dy: i64, axis: usize) i64 {
    const x=input[1+2*index]; const y=input[2+2*index];
    return if (axis==2) dx*y-dy*x else dx*x+dy*y;
}

export fn minimum_area_enclosing_rectangle(input_opt: ?[*]const i64, length: usize,
                                           output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt==null or length<7 or length>34) return -1;
    const input=input_opt.?;
    if (input[0]<3 or input[0]>16) return -1;
    const n: usize=@intCast(input[0]);
    if (length!=1+2*n) return -1;
    for (1..length) |i| if (input[i]< -100 or input[i]>100) return -1;
    for (0..n) |i| {
        const next=(i+1)%n;
        const ax=input[1+2*i]; const ay=input[2+2*i];
        const dx=input[1+2*next]-ax; const dy=input[2+2*next]-ay;
        for (0..n) |j| if (j!=i and j!=next) {
            if (dx*(input[2+2*j]-ay)-dy*(input[1+2*j]-ax)<=0) return -1;
        };
    }
    const first_dx=input[3]-input[1]; const first_dy=input[4]-input[2];
    var supports: [3]usize=@splat(0);
    for (1..n) |i| for (0..3) |axis| {
        const current=projection(input,supports[axis],first_dx,first_dy,axis);
        const candidate=projection(input,i,first_dx,first_dy,axis);
        if ((axis==1 and candidate<current) or (axis!=1 and candidate>current)) supports[axis]=i;
    };
    var best_num: i64=0; var best_den: i64=1;
    for (0..n) |i| {
        const next=(i+1)%n;
        const ax=input[1+2*i]; const ay=input[2+2*i];
        const dx=input[1+2*next]-ax; const dy=input[2+2*next]-ay;
        for (0..3) |axis| for (0..n) |_| {
            const following=(supports[axis]+1)%n;
            const current=projection(input,supports[axis],dx,dy,axis);
            const candidate=projection(input,following,dx,dy,axis);
            if ((axis==1 and candidate<=current) or (axis!=1 and candidate>=current)) supports[axis]=following
            else break;
        };
        const span=projection(input,supports[0],dx,dy,0)-projection(input,supports[1],dx,dy,1);
        const thickness=projection(input,supports[2],dx,dy,2)-(dx*ay-dy*ax);
        const numerator=span*thickness; const denominator=dx*dx+dy*dy;
        if (i==0 or numerator*best_den<best_num*denominator) { best_num=numerator; best_den=denominator; }
    }
    var a=best_num; var b=best_den;
    while (b!=0) { const remainder=@rem(a,b); a=b; b=remainder; }
    const words=[_]i64{@divTrunc(best_num,a),@divTrunc(best_den,a)};
    if (output_opt==null or capacity<16) return -2;
    const output=output_opt.?;
    for (words,0..) |word,i| {
        const bits: u64=@bitCast(word);
        for (0..8) |j| output[8*i+j]=@truncate(bits >> @intCast(8*j));
    }
    return 16;
}
