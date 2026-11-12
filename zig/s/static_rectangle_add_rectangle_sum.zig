const max_n: usize = 32;
const max_q: usize = 32;
const max_coords: usize = 128;
const stride: usize = 129;
const modulus: i64 = 998244353;

fn lower(a: *const [max_coords]i64, n: usize, x: i64) usize {
    var lo: usize = 0;
    var hi = n;
    while (lo < hi) { const mid=lo+(hi-lo)/2; if(a[mid]<x){lo=mid+1;}else{hi=mid;} }
    return lo;
}
fn put64(output: [*]u8, at: usize, value: i64) void {
    const bits: u64=@bitCast(value);
    for(0..8)|b| output[at+b]=@truncate(bits>>(8*b));
}

export fn static_rectangle_add_rectangle_sum(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if(input_opt==null or length<2 or length>291)return -1;
    const input=input_opt.?;
    const n64=input[0];const q64=input[1];
    if(n64<1 or n64>32 or q64<0 or q64>32)return -1;
    const n:usize=@intCast(n64);const q:usize=@intCast(q64);
    if(length!=2+5*n+4*q)return -1;
    var ul=[_]i64{0}**max_n;var ud=[_]i64{0}**max_n;var ur=[_]i64{0}**max_n;var uu=[_]i64{0}**max_n;var uw=[_]i64{0}**max_n;
    var ql=[_]i64{0}**max_q;var qd=[_]i64{0}**max_q;var qr=[_]i64{0}**max_q;var qu=[_]i64{0}**max_q;
    var xs=[_]i64{0}**max_coords;var ys=[_]i64{0}**max_coords;var nx:usize=0;var ny:usize=0;var off:usize=2;
    for(0..n)|i|{ul[i]=input[off];ud[i]=input[off+1];ur[i]=input[off+2];uu[i]=input[off+3];uw[i]=input[off+4];off+=5;
        if(ul[i]<0 or ul[i]>=ur[i] or ur[i]>1_000_000 or ud[i]<0 or ud[i]>=uu[i] or uu[i]>1_000_000 or uw[i]<0 or uw[i]>=modulus)return -1;
        xs[nx]=ul[i];xs[nx+1]=ur[i];ys[ny]=ud[i];ys[ny+1]=uu[i];nx+=2;ny+=2;}
    for(0..q)|i|{ql[i]=input[off];qd[i]=input[off+1];qr[i]=input[off+2];qu[i]=input[off+3];off+=4;
        if(ql[i]<0 or ql[i]>=qr[i] or qr[i]>1_000_000 or qd[i]<0 or qd[i]>=qu[i] or qu[i]>1_000_000)return -1;
        xs[nx]=ql[i];xs[nx+1]=qr[i];ys[ny]=qd[i];ys[ny+1]=qu[i];nx+=2;ny+=2;}
    var i:usize=1;while(i<nx):(i+=1){const value=xs[i];var j=i;while(j>0 and xs[j-1]>value):(j-=1){xs[j]=xs[j-1];}xs[j]=value;}
    i=1;while(i<ny):(i+=1){const value=ys[i];var j=i;while(j>0 and ys[j-1]>value):(j-=1){ys[j]=ys[j-1];}ys[j]=value;}
    var count:usize=0;for(0..nx)|r|{const value=xs[r];if(count==0 or xs[count-1]!=value){xs[count]=value;count+=1;}}nx=count;
    count=0;for(0..ny)|r|{const value=ys[r];if(count==0 or ys[count-1]!=value){ys[count]=value;count+=1;}}ny=count;
    var diff=[_]i64{0}**(max_coords*max_coords);var prefix=[_]i64{0}**(stride*stride);
    for(0..n)|k|{const x0=lower(&xs,nx,ul[k]);const x1=lower(&xs,nx,ur[k]);const y0=lower(&ys,ny,ud[k]);const y1=lower(&ys,ny,uu[k]);diff[x0*max_coords+y0]+=uw[k];diff[x1*max_coords+y0]-=uw[k];diff[x0*max_coords+y1]-=uw[k];diff[x1*max_coords+y1]+=uw[k];}
    for(0..nx)|r|{for(0..ny)|c|{const at=r*max_coords+c;var value=diff[at];if(r>0)value+=diff[(r-1)*max_coords+c];if(c>0)value+=diff[r*max_coords+c-1];if(r>0 and c>0)value-=diff[(r-1)*max_coords+c-1];diff[at]=value;}}
    if(nx>1 and ny>1){for(0..nx-1)|r|{for(0..ny-1)|c|{const value=@mod(diff[r*max_coords+c],modulus);const dx=@mod(xs[r+1]-xs[r],modulus);const dy=@mod(ys[c+1]-ys[c],modulus);const cell=@mod(value*@mod(dx*dy,modulus),modulus);const at=(r+1)*stride+c+1;const sum=@mod(cell+prefix[r*stride+c+1]+prefix[(r+1)*stride+c]-prefix[r*stride+c],modulus);prefix[at]=sum;}}}
    var answers=[_]i64{0}**max_q;
    for(0..q)|k|{const x0=lower(&xs,nx,ql[k]);const x1=lower(&xs,nx,qr[k]);const y0=lower(&ys,ny,qd[k]);const y1=lower(&ys,ny,qu[k]);answers[k]=@mod(prefix[x1*stride+y1]-prefix[x0*stride+y1]-prefix[x1*stride+y0]+prefix[x0*stride+y0],modulus);}
    const bytes=8*q;if(output_opt==null or capacity<bytes)return -2;const output=output_opt.?;for(0..q)|k|put64(output,8*k,answers[k]);return @intCast(bytes);
}
