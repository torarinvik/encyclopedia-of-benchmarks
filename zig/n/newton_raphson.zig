export fn newton_raphson(values: [*c]const i64, length: usize) f64 {
    if (values == null or length != 2) return -1.0e300;
    const n=values[0]; const q=values[1];
    if(n<2 or n>4 or q<4 or q>8)return -1.0e300;
    var x=@as(f64,@floatFromInt(q))/4.0;
    for(0..8)|_|{x=0.5*(x+@as(f64,@floatFromInt(n))/x);}
    return x;
}
