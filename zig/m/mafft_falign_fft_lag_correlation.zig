// Clean-room bounded MAFFT Falign FFT lag profile; see package LICENSE.txt.
const std = @import("std");
const max_n: usize = 64;
const channel_count: usize = 20;
const amino_codes = [_]i64{65,82,78,68,67,81,69,71,72,73,76,75,77,70,80,83,84,87,89,86};
const polarity = [_]f64{8.1,10.5,11.6,13.0,5.5,10.5,12.3,9.0,10.4,5.2,4.9,11.3,5.7,5.2,8.0,9.2,8.6,5.4,6.2,5.9};
const volume = [_]f64{31.0,124.0,56.0,54.0,55.0,85.0,83.0,3.0,96.0,111.0,111.0,119.0,105.0,132.0,32.5,32.0,61.0,170.0,136.0,84.0};
fn channel(code: i64) ?usize { for (amino_codes,0..) |v,q| {if(v==code)return q;} return null; }
fn fft(re: *[max_n]f64, im: *[max_n]f64, n: usize, inverse: bool) void {
    var j: usize=0;var i:usize=1;
    while(i<n):(i+=1){var bit=n>>1;while((j&bit)!=0){j^=bit;bit>>=1;}j^=bit;if(i<j){std.mem.swap(f64,&re[i],&re[j]);std.mem.swap(f64,&im[i],&im[j]);}}
    var span:usize=2;while(span<=n):(span*=2){const sign:f64=if(inverse) 1.0 else -1.0;const angle=sign*6.2831853071795864769/@as(f64,@floatFromInt(span));const cr=@cos(angle);const ci=@sin(angle);var start:usize=0;while(start<n):(start+=span){var wr:f64=1;var wi:f64=0;for(0..span/2)|k|{const u=start+k;const v=u+span/2;const pr=wr*re[v]-wi*im[v];const pi=wr*im[v]+wi*re[v];const ur=re[u];const ui=im[u];re[u]=ur+pr;im[u]=ui+pi;re[v]=ur-pr;im[v]=ui-pi;const nw=wr*cr-wi*ci;wi=wr*ci+wi*cr;wr=nw;}}}
    if(!inverse)for(0..n)|q|{re[q]/=@floatFromInt(n);im[q]/=@floatFromInt(n);};
}

export fn mafft_falign_fft_lag_correlation(input_opt:?[*]const f64,length:usize,output_opt:?[*]f64,capacity:usize)i64{
    if(input_opt==null or length<4 or length>66)return -1;const input=input_opt.?;
    for(0..length)|q|{const v=input[q];if(!std.math.isFinite(v) or @trunc(v)!=v)return -1;}
    if(input[0]<1 or input[0]>32 or input[1]<1 or input[1]>32)return -1;
    const n1:usize=@intFromFloat(input[0]);const n2:usize=@intFromFloat(input[1]);if(length!=2+n1+n2)return -1;
    for(2..length)|q|{if(input[q]<65 or input[q]>90 or channel(@intFromFloat(input[q]))==null)return -1;}
    var n:usize=1;while(n<=@max(n1,n2)):(n*=2){}if(output_opt==null or capacity<n)return -2;
    var r1:[max_n]f64=[_]f64{0.0} ** max_n;var i1:[max_n]f64=[_]f64{0.0} ** max_n;var r2:[max_n]f64=[_]f64{0.0} ** max_n;var i2:[max_n]f64=[_]f64{0.0} ** max_n;var re:[max_n]f64=[_]f64{0.0} ** max_n;var im:[max_n]f64=[_]f64{0.0} ** max_n;
    var mp:f64=0;var mv:f64=0;for(0..channel_count)|ch|{mp+=polarity[ch];mv+=volume[ch];}mp/=20.0;mv/=20.0;
    var vp:f64=0;var vv:f64=0;for(0..channel_count)|ch|{const dp=polarity[ch]-mp;const dv=volume[ch]-mv;vp+=dp*dp;vv+=dv*dv;}const sp=@sqrt(vp/20.0);const sv=@sqrt(vv/20.0);
    for(0..n1)|p|{const ch=channel(@intFromFloat(input[2+p])).?;r1[p]=(polarity[ch]-mp)/sp;i1[p]=(volume[ch]-mv)/sv;}
    for(0..n2)|p|{const ch=channel(@intFromFloat(input[2+n1+p])).?;r2[p]=(polarity[ch]-mp)/sp;i2[p]=(volume[ch]-mv)/sv;}
    fft(&r1,&i1,n,false);fft(&r2,&i2,n,false);for(0..n)|k|{re[k]=r1[k]*r2[k]+i1[k]*i2[k];im[k]= -r1[k]*i2[k]+i1[k]*r2[k];}
    fft(&re,&im,n,true);const output=output_opt.?;for(0..n)|q|{output[q]=re[(n/2+n-q)%n];}return @intCast(n);
}
