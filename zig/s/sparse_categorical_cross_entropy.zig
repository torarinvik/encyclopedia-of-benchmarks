const INVALID:f64=-1.0e300;const SCALE:f64=1000000.0;
export fn sparse_categorical_cross_entropy(values:[*]const i64,length:usize) f64{
    if(length<2)return INVALID;const batch=values[0];const classes=values[1];if(batch<1 or batch>32 or classes<1 or classes>32)return INVALID;const b:usize=@intCast(batch);const c:usize=@intCast(classes);if(length!=2+b+b*c)return INVALID;
    for(0..b)|r|{const label=values[2+r];if(label<0 or label>=classes)return INVALID;var sum:i64=0;for(0..c)|col|{const x=values[2+b+r*c+col];if(x<0 or x>1000000)return INVALID;sum+=x;}if(sum!=1000000)return INVALID;}
    var total:f64=0;for(0..b)|r|{const label:usize=@intCast(values[2+r]);const x=@as(f64,@floatFromInt(values[2+b+r*c+label]))/SCALE;total-=@log(@max(1e-15,@min(1.0,x)));}return total;
}
