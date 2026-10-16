const std = @import("std");
const critical = [_]f64{0,0,0,1.1543048513440384,1.48125,1.715037312343363,1.887145117783933,2.0199685076795957,2.126645087195462};
export fn generalized_esd(v: [*]const i64, length: usize) i64 {
 if(length<5)return -1;const n=v[0];const limit=v[1];if(n<3 or n>8 or limit<1 or limit>3 or limit>n-2 or length!=@as(usize,@intCast(n))+2)return -1;
 var x:[8]f64=undefined;var idx:[8]usize=undefined;for(0..@as(usize,@intCast(n)))|i|{if(v[i+2]<-10000 or v[i+2]>10000)return -1;x[i]=@floatFromInt(v[i+2]);idx[i]=i;}
 var remaining:usize=@intCast(n);var accepted:usize=0;var removed:[3]usize=undefined;var step:usize=1;while(step<=@as(usize,@intCast(limit))):(step+=1){var mean:f64=0;for(0..remaining)|i|{mean+=x[i];}mean/=@floatFromInt(remaining);var ss:f64=0;for(0..remaining)|i|{const d=x[i]-mean;ss+=d*d;}const sd=@sqrt(ss/@as(f64,@floatFromInt(remaining-1)));if(sd==0)break;var worst:usize=0;var largest:f64=-1;for(0..remaining)|i|{const d=@abs(x[i]-mean);if(d>largest){largest=d;worst=i;}}removed[step-1]=idx[worst];if(largest/sd>critical[remaining])accepted=step;remaining-=1;x[worst]=x[remaining];idx[worst]=idx[remaining];}
 var mask:i64=0;for(0..accepted)|i|{mask|=@as(i64,1)<<@intCast(removed[i]);}return mask;
}
