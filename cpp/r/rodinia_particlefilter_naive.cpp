// Rodinia particlefilter_naive one-transition profile; full notice: benchmarks/r/rodinia_particlefilter_naive/LICENSE.txt.
#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_particles=4,max_samples=4;
constexpr double scale=1000000.0;
std::int64_t round_away(double value){const double scaled=value*1000.0;return scaled<0.0?-static_cast<std::int64_t>(std::floor(-scaled+0.5)):static_cast<std::int64_t>(std::floor(scaled+0.5));}
}

extern "C" std::int64_t rodinia_particlefilter_naive(const std::int64_t* input,std::size_t length){
    if(input==nullptr||length<8||length>35)return -1;
    const auto n_raw=input[0],samples_raw=input[1],offset_raw=input[2];
    if(n_raw<1||n_raw>static_cast<std::int64_t>(max_particles)||samples_raw<1||samples_raw>static_cast<std::int64_t>(max_samples))return -1;
    const auto n=static_cast<std::size_t>(n_raw),samples=static_cast<std::size_t>(samples_raw);
    if(length!=3+n*(4+samples)||offset_raw<0||offset_raw>=1000000||offset_raw*n_raw>=1000000)return -1;
    double x[4],y[4],moved_x[4],moved_y[4],weights[4],cdf[4],selected_x[4],selected_y[4];
    for(std::size_t i=0;i<n;++i){const std::size_t at=3+i*(4+samples);const auto xr=input[at],yr=input[at+1],nxr=input[at+2],nyr=input[at+3];
        if(xr< -100000000||xr>100000000||yr< -100000000||yr>100000000||nxr< -2000000||nxr>2000000||nyr< -2000000||nyr>2000000)return -1;
        x[i]=static_cast<double>(xr)/scale;y[i]=static_cast<double>(yr)/scale;
        moved_x[i]=x[i]+1.0+5.0*(static_cast<double>(nxr)/scale);moved_y[i]=y[i]-2.0+2.0*(static_cast<double>(nyr)/scale);
        double likelihood_sum=0.0;for(std::size_t j=0;j<samples;++j){const auto intensity=input[at+4+j];if(intensity<0||intensity>255)return -1;const double fg=static_cast<double>(intensity-100),bg=static_cast<double>(intensity-228);likelihood_sum+=(fg*fg-bg*bg)/50.0;}
        const double likelihood=likelihood_sum/static_cast<double>(samples);weights[i]=(1.0/static_cast<double>(n))*std::exp(likelihood);
    }
    double weight_sum=0.0;for(std::size_t i=0;i<n;++i)weight_sum+=weights[i];if(!std::isfinite(weight_sum)||weight_sum<=0.0)return -1;
    for(std::size_t i=0;i<n;++i)weights[i]/=weight_sum;
    double estimate_x=0.0,estimate_y=0.0;for(std::size_t i=0;i<n;++i){estimate_x+=moved_x[i]*weights[i];estimate_y+=moved_y[i]*weights[i];}
    cdf[0]=weights[0];for(std::size_t i=1;i<n;++i)cdf[i]=weights[i]+cdf[i-1];const double offset=static_cast<double>(offset_raw)/scale;
    for(std::size_t i=0;i<n;++i){const double u=offset+static_cast<double>(i)/static_cast<double>(n);std::size_t selected=n-1;for(std::size_t j=0;j<n;++j)if(cdf[j]>=u){selected=j;break;}selected_x[i]=moved_x[selected];selected_y[i]=moved_y[selected];}
    std::int64_t checksum=round_away(estimate_x)+2*round_away(estimate_y);for(std::size_t i=0;i<n;++i)checksum+=static_cast<std::int64_t>(2*i+3)*round_away(selected_x[i])+static_cast<std::int64_t>(2*i+4)*round_away(selected_y[i]);return checksum;
}
