/* Rodinia particlefilter_naive one-transition profile; full notice: benchmarks/r/rodinia_particlefilter_naive/LICENSE.txt. */
#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_PARTICLES 4
#define MAX_SAMPLES 4
#define SCALE 1000000.0

static int64_t round_away(double value) {
    double scaled=value*1000.0;
    return scaled<0.0?-(int64_t)floor(-scaled+0.5):(int64_t)floor(scaled+0.5);
}

int64_t rodinia_particlefilter_naive(const int64_t *input,size_t length) {
    if(input==NULL||length<8||length>35)return -1;
    int64_t n_raw=input[0],s_raw=input[1],offset_raw=input[2];
    if(n_raw<1||n_raw>MAX_PARTICLES||s_raw<1||s_raw>MAX_SAMPLES)return -1;
    size_t n=(size_t)n_raw,samples=(size_t)s_raw;
    if(length!=3+n*(4+samples)||offset_raw<0||offset_raw>=1000000||offset_raw*n_raw>=1000000)return -1;
    double x[MAX_PARTICLES],y[MAX_PARTICLES],moved_x[MAX_PARTICLES],moved_y[MAX_PARTICLES];
    double weights[MAX_PARTICLES],cdf[MAX_PARTICLES],resampled_x[MAX_PARTICLES],resampled_y[MAX_PARTICLES];
    for(size_t i=0;i<n;i++){
        size_t at=3+i*(4+samples);
        int64_t xr=input[at],yr=input[at+1],nxr=input[at+2],nyr=input[at+3];
        if(xr< -100000000||xr>100000000||yr< -100000000||yr>100000000||nxr< -2000000||nxr>2000000||nyr< -2000000||nyr>2000000)return -1;
        x[i]=(double)xr/SCALE;y[i]=(double)yr/SCALE;
        moved_x[i]=x[i]+1.0+5.0*((double)nxr/SCALE);
        moved_y[i]=y[i]-2.0+2.0*((double)nyr/SCALE);
        double likelihood_sum=0.0;
        for(size_t j=0;j<samples;j++){
            int64_t intensity=input[at+4+j];if(intensity<0||intensity>255)return -1;
            double foreground=(double)(intensity-100),background=(double)(intensity-228);
            likelihood_sum+=(foreground*foreground-background*background)/50.0;
        }
        double likelihood=likelihood_sum/(double)samples;
        weights[i]=(1.0/(double)n)*exp(likelihood);
    }
    double weight_sum=0.0;for(size_t i=0;i<n;i++)weight_sum+=weights[i];
    if(!isfinite(weight_sum)||weight_sum<=0.0)return -1;
    for(size_t i=0;i<n;i++)weights[i]/=weight_sum;
    double estimate_x=0.0,estimate_y=0.0;
    for(size_t i=0;i<n;i++){estimate_x+=moved_x[i]*weights[i];estimate_y+=moved_y[i]*weights[i];}
    cdf[0]=weights[0];for(size_t i=1;i<n;i++)cdf[i]=weights[i]+cdf[i-1];
    double offset=(double)offset_raw/SCALE;
    for(size_t i=0;i<n;i++){
        double u=offset+(double)i/(double)n;size_t selected=n-1;
        for(size_t j=0;j<n;j++)if(cdf[j]>=u){selected=j;break;}
        resampled_x[i]=moved_x[selected];resampled_y[i]=moved_y[selected];
    }
    int64_t checksum=round_away(estimate_x)+2*round_away(estimate_y);
    for(size_t i=0;i<n;i++)checksum+=(int64_t)(2*i+3)*round_away(resampled_x[i])+(int64_t)(2*i+4)*round_away(resampled_y[i]);
    return checksum;
}
