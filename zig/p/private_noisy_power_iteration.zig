const scale:i64=1_000_000;
const max_input:usize=39;

fn trunc_div(value:i64,denominator:i64)i64{return @divTrunc(value,denominator);}
fn floor_sqrt(value:i64)i64{
    var low:i64=0;var high:i64=13_000_001;
    while(low+1<high){const middle=@divTrunc(low+high,2);if(middle<=@divTrunc(value,middle)){low=middle;}else{high=middle;}}
    return low;
}
fn put64(out:[*]u8,pos:usize,value:i64)void{
    const bits:u64=@bitCast(value);
    for(0..8)|j|out[pos+j]=@truncate(bits>>@intCast(8*j));
}

export fn private_noisy_power_iteration(input_opt:?[*]const i64,length:usize,
    output_opt:?[*]u8,capacity:usize)i64{
    if(input_opt==null||length<11||length>max_input)return -1;
    const input=input_opt.?;const n64=input[0];const rounds64=input[1];const sigma=input[2];
    if(n64<2 or n64>4 or rounds64<1 or rounds64>4 or sigma<0 or sigma>scale)return -1;
    const n:usize=@intCast(n64);const rounds:usize=@intCast(rounds64);const expected=3+n*n+n+rounds*n;
    if(length!=expected)return -1;
    const vector_start=3+n*n;const noise_start=vector_start+n;
    var matrix:[16]i64=@splat(0);var x:[4]i64=@splat(0);var noise:[16]i64=@splat(0);
    for(0..n*n)|i|{matrix[i]=input[3+i];if(matrix[i]<-scale or matrix[i]>scale)return -1;}
    for(0..n)|i|{for(0..n)|j|{if(matrix[i*n+j]!=matrix[j*n+i])return -1;}}
    var initial_norm:i64=0;
    for(0..n)|i|{x[i]=input[vector_start+i];if(x[i]<-scale or x[i]>scale)return -1;initial_norm+=x[i]*x[i];}
    if(initial_norm!=scale*scale)return -1;
    for(0..rounds*n)|i|{noise[i]=input[noise_start+i];if(noise[i]<-2*scale or noise[i]>2*scale)return -1;}
    var y:[4]i64=@splat(0);
    for(0..rounds)|step|{
        var norm_sq:i64=0;
        for(0..n)|i|{var sum=sigma*noise[step*n+i];for(0..n)|j|{sum+=matrix[i*n+j]*x[j];}y[i]=trunc_div(sum,scale);norm_sq+=y[i]*y[i];}
        if(norm_sq==0)return -1;
        const radius=floor_sqrt(norm_sq);
        for(0..n)|i|{x[i]=trunc_div(y[i]*scale,radius);}
    }
    const bytes=8*n;if(output_opt==null or capacity<bytes)return -2;
    var staged:[32]u8=@splat(0);for(0..n)|i|put64(&staged,8*i,x[i]);
    const output=output_opt.?;for(0..bytes)|i|output[i]=staged[i];return @intCast(bytes);
}
