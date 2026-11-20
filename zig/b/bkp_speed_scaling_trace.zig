const max_jobs: usize = 4;
const max_samples: usize = 8;
const max_bytes: usize = 136;
const e_num: i64 = 271828;
const e_den: i64 = 100000;
const em1_num: i64 = 171828;

fn gcd64(a0: i64, b0: i64) i64 {
    var a=a0; var b=b0;
    while (b!=0) { const r=@rem(a,b); a=b; b=r; }
    return if (a<0) -a else a;
}
fn consider(r: *const [max_jobs]i64,d: *const [max_jobs]i64,w: *const [max_jobs]i64,
    n: usize,t: i64,x_num: i64,x_den: i64,bn: *i64,bd: *i64) void {
    const delta=x_num-t*x_den;
    if (delta<=0) return;
    const left=e_num*t*x_den-em1_num*x_num;
    var total: i64=0;
    for (0..n) |j| {
        if (r[j]<=t and left<=e_den*x_den*r[j] and d[j]*x_den<=x_num) total+=w[j];
    }
    const numerator=total*x_den;
    if (numerator * bd.* > bn.* * delta) { bn.*=numerator; bd.*=delta; }
}
fn put64(out: [*]u8,at: usize,value: i64) void {
    const bits: u64=@bitCast(value);
    for (0..8) |b| out[at+b]=@truncate(bits>>@intCast(8*b));
}

export fn bkp_speed_scaling_trace(input_opt: ?[*]const i64,length: usize,
    output_opt: ?[*]u8,capacity: usize) i64 {
    if (input_opt==null or length<2 or length>31) return -1;
    const input=input_opt.?;
    if (input[0]<1 or input[0]>4 or input[1]<1 or input[1]>8) return -1;
    const n: usize=@intCast(input[0]); const samples: usize=@intCast(input[1]);
    if (length!=2+3*n+2*samples) return -1;
    var r: [max_jobs]i64=@splat(0); var d: [max_jobs]i64=@splat(0); var w: [max_jobs]i64=@splat(0);
    for (0..n) |j| {
        r[j]=input[2+3*j]; d[j]=input[3+3*j]; w[j]=input[4+3*j];
        if (r[j]<0 or r[j]>=d[j] or d[j]>8 or w[j]<1 or w[j]>8) return -1;
    }
    var values: [17]i64=@splat(0); values[0]=@intCast(samples);
    for (0..samples) |s| {
        const t=input[2+3*n+2*s]; const mask=input[3+3*n+2*s];
        if (t<0 or t>8 or mask<0 or mask>=(@as(i64,1)<<@intCast(n))) return -1;
        for (0..n) |j| {
            if ((mask&(@as(i64,1)<<@intCast(j)))!=0 and r[j]>t) return -1;
        }
        var bn: i64=0; var bd: i64=1;
        if (mask!=0) {
            for (0..n) |j| {
                if (r[j]<=t) {
                    if (d[j]>t) consider(&r,&d,&w,n,t,d[j],1,&bn,&bd);
                    if (r[j]<t) consider(&r,&d,&w,n,t,e_num*t-e_den*r[j],em1_num,&bn,&bd);
                }
            }
        }
        const g=gcd64(bn,bd); values[1+2*s]=@divTrunc(bn,g); values[2+2*s]=@divTrunc(bd,g);
    }
    const bytes=8*(1+2*samples);
    if (output_opt==null or capacity<bytes) return -2;
    const output=output_opt.?;
    var staged: [max_bytes]u8=@splat(0);
    for (0..1+2*samples) |i| put64(&staged,8*i,values[i]);
    @memcpy(output[0..bytes],staged[0..bytes]);
    return @intCast(bytes);
}
