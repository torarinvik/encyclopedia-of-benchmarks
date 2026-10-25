// Rodinia particlefilter_naive one-transition profile; full notice: benchmarks/r/rodinia_particlefilter_naive/LICENSE.txt.
package rodinia_particlefilter_naive

import "core:c"
import "core:math"

SCALE :: 1000000.0
round_away :: proc "contextless" (value:f64)->i64{scaled:=value*1000.0;if scaled<0 do return -i64(math.floor(-scaled+0.5));return i64(math.floor(scaled+0.5))}

@(export)
rodinia_particlefilter_naive :: proc "c" (input:[^]i64,length:c.size_t)->i64 {
    if input==nil||length<8||length>35 do return -1
    n_raw,samples_raw,offset_raw:=input[0],input[1],input[2]
    if n_raw<1||n_raw>4||samples_raw<1||samples_raw>4 do return -1
    n,samples:=int(n_raw),int(samples_raw)
    if int(length)!=3+n*(4+samples)||offset_raw<0||offset_raw>=1000000||offset_raw*n_raw>=1000000 do return -1
    x,y,moved_x,moved_y,weights,cdf,resampled_x,resampled_y:=[4]f64{}
    for i:=0;i<n;i+=1{
        at:=3+i*(4+samples);xr,yr,nxr,nyr:=input[at],input[at+1],input[at+2],input[at+3]
        if xr< -100000000||xr>100000000||yr< -100000000||yr>100000000||nxr< -2000000||nxr>2000000||nyr< -2000000||nyr>2000000 do return -1
        x[i],y[i]=f64(xr)/SCALE,f64(yr)/SCALE;moved_x[i]=x[i]+1.0+5.0*(f64(nxr)/SCALE);moved_y[i]=y[i]-2.0+2.0*(f64(nyr)/SCALE)
        likelihood_sum:f64=0.0
        for j:=0;j<samples;j+=1{intensity:=input[at+4+j];if intensity<0||intensity>255 do return -1;foreground,background:=f64(intensity-100),f64(intensity-228);likelihood_sum+=(foreground*foreground-background*background)/50.0}
        likelihood:=likelihood_sum/f64(samples);weights[i]=(1.0/f64(n))*math.exp_f64(likelihood)
    }
    weight_sum:f64=0.0;for i:=0;i<n;i+=1{weight_sum+=weights[i]};if !math.is_finite(weight_sum)||weight_sum<=0 do return -1
    for i:=0;i<n;i+=1{weights[i]/=weight_sum}
    estimate_x,estimate_y:f64=0.0,0.0;for i:=0;i<n;i+=1{estimate_x+=moved_x[i]*weights[i];estimate_y+=moved_y[i]*weights[i]}
    cdf[0]=weights[0];for i:=1;i<n;i+=1{cdf[i]=weights[i]+cdf[i-1]};offset:=f64(offset_raw)/SCALE
    for i:=0;i<n;i+=1{u:=offset+f64(i)/f64(n);selected:=n-1;for j:=0;j<n;j+=1{if cdf[j]>=u{selected=j;break}};resampled_x[i]=moved_x[selected];resampled_y[i]=moved_y[selected]}
    checksum:=round_away(estimate_x)+2*round_away(estimate_y);for i:=0;i<n;i+=1{checksum+=i64(2*i+3)*round_away(resampled_x[i])+i64(2*i+4)*round_away(resampled_y[i])};return checksum
}
