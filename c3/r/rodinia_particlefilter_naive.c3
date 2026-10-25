// Rodinia particlefilter_naive one-transition profile; full notice: benchmarks/r/rodinia_particlefilter_naive/LICENSE.txt.
module rodinia_particlefilter_naive;
import "math";

const long MAX_PARTICLES=4,MAX_SAMPLES=4;
const double SCALE=1000000.0;
fn long round_away(double value){double scaled=value*1000.0;return scaled<0.0?-(long)math.floor(-scaled+0.5):(long)math.floor(scaled+0.5);}

fn long rodinia_particlefilter_naive(long* input,usz length) @export("rodinia_particlefilter_naive") {
    if(input==null||length<8||length>35)return -1;
    long n_raw=input[0],samples_raw=input[1],offset_raw=input[2];
    if(n_raw<1||n_raw>MAX_PARTICLES||samples_raw<1||samples_raw>MAX_SAMPLES)return -1;
    usz n=(usz)n_raw,samples=(usz)samples_raw;
    if(length!=3+n*(4+samples)||offset_raw<0||offset_raw>=1000000||offset_raw*n_raw>=1000000)return -1;
    double[4] x,y,moved_x,moved_y,weights,cdf,resampled_x,resampled_y;
    for(usz i=0;i<n;i++){
        usz at=3+i*(4+samples);long xr=input[at],yr=input[at+1],nxr=input[at+2],nyr=input[at+3];
        if(xr< -100000000||xr>100000000||yr< -100000000||yr>100000000||nxr< -2000000||nxr>2000000||nyr< -2000000||nyr>2000000)return -1;
        x[i]=(double)xr/SCALE;y[i]=(double)yr/SCALE;moved_x[i]=x[i]+1.0+5.0*((double)nxr/SCALE);moved_y[i]=y[i]-2.0+2.0*((double)nyr/SCALE);
        double likelihood_sum=0.0;
        for(usz j=0;j<samples;j++){long intensity=input[at+4+j];if(intensity<0||intensity>255)return -1;double fg=(double)(intensity-100),bg=(double)(intensity-228);likelihood_sum+=(fg*fg-bg*bg)/50.0;}
        double likelihood=likelihood_sum/(double)samples;weights[i]=(1.0/(double)n)*math.exp(likelihood);
    }
    double weight_sum=0.0;for(usz i=0;i<n;i++)weight_sum+=weights[i];if(!math.is_finite(weight_sum)||weight_sum<=0.0)return -1;
    for(usz i=0;i<n;i++)weights[i]/=weight_sum;
    double estimate_x=0.0,estimate_y=0.0;for(usz i=0;i<n;i++){estimate_x+=moved_x[i]*weights[i];estimate_y+=moved_y[i]*weights[i];}
    cdf[0]=weights[0];for(usz i=1;i<n;i++)cdf[i]=weights[i]+cdf[i-1];double offset=(double)offset_raw/SCALE;
    for(usz i=0;i<n;i++){double u=offset+(double)i/(double)n;usz selected=n-1;for(usz j=0;j<n;j++)if(cdf[j]>=u){selected=j;break;}resampled_x[i]=moved_x[selected];resampled_y[i]=moved_y[selected];}
    long checksum=round_away(estimate_x)+2*round_away(estimate_y);for(usz i=0;i<n;i++)checksum+=(long)(2*i+3)*round_away(resampled_x[i])+(long)(2*i+4)*round_away(resampled_y[i]);return checksum;
}
