#include <math.h>
#include <stddef.h>
#include <stdint.h>
#include <string.h>

#define MAX_INPUT 2054
#define MAX_AUDIO 2048
#define MAX_FFT 1024
#define MAX_FRAMES 257
#define MAX_MELS 16
#define MAX_DCTS 40
#define PI 3.14159265358979323846264338327950288

static void fft(double *re, double *im, size_t n) {
    size_t j = 0;
    for (size_t i = 1; i < n; ++i) {
        size_t bit = n >> 1;
        while (j & bit) { j ^= bit; bit >>= 1; }
        j ^= bit;
        if (i < j) {
            double t = re[i]; re[i] = re[j]; re[j] = t;
            t = im[i]; im[i] = im[j]; im[j] = t;
        }
    }
    for (size_t len = 2; len <= n; len <<= 1) {
        double angle = -2.0 * PI / (double)len;
        double sr = cos(angle), si = sin(angle);
        size_t half = len >> 1;
        for (size_t start = 0; start < n; start += len) {
            double wr = 1.0, wi = 0.0;
            for (size_t k = 0; k < half; ++k) {
                size_t even = start + k, odd = even + half;
                double tr = wr * re[odd] - wi * im[odd];
                double ti = wr * im[odd] + wi * re[odd];
                re[odd] = re[even] - tr; im[odd] = im[even] - ti;
                re[even] += tr; im[even] += ti;
                double next_wr = wr * sr - wi * si;
                wi = wr * si + wi * sr; wr = next_wr;
            }
        }
    }
}

static double mel_to_hz(double mel) { return 700.0 * (pow(10.0, mel / 2595.0) - 1.0); }
static double hz_to_mel(double hz) { return 2595.0 * log10(1.0 + hz / 700.0); }
static void put_f64_le(uint8_t *dst, double value) {
    uint64_t bits; memcpy(&bits, &value, sizeof(bits));
    for (size_t b = 0; b < 8; ++b) dst[b] = (uint8_t)(bits >> (8 * b));
}

int64_t mfcc(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 6 || length > MAX_INPUT) return -1;
    int64_t n64=input[0], sr64=input[1], hop_ms64=input[2], fft64=input[3], mel64=input[4], dct64=input[5];
    if (n64 < 33 || n64 > MAX_AUDIO || length != (size_t)n64 + 6) return -1;
    if (sr64 < 8000 || sr64 > 48000 || hop_ms64 < 1 || hop_ms64 > 50) return -1;
    if (!(fft64==64 || fft64==128 || fft64==256 || fft64==512 || fft64==1024)) return -1;
    if (mel64 < 2 || mel64 > MAX_MELS || dct64 < 1 || dct64 > MAX_DCTS) return -1;
    size_t n=(size_t)n64, sr=(size_t)sr64, fft_n=(size_t)fft64, mels=(size_t)mel64, dcts=(size_t)dct64;
    if (n < fft_n/2 + 1) return -1;
    size_t hop=(size_t)nearbyint((double)sr*(double)hop_ms64/1000.0);
    if (hop == 0) return -1;
    double audio[MAX_AUDIO], peak=0.0;
    for (size_t i=0;i<n;++i) {
        uint64_t bits=(uint64_t)input[6+i];
        double sample; memcpy(&sample,&bits,sizeof(sample));
        if (!isfinite(sample) || fabs(sample)>1000000.0) return -1;
        audio[i]=sample; if (fabs(sample)>peak) peak=fabs(sample);
    }
    if (peak == 0.0) return -1;
    for(size_t i=0;i<n;++i) audio[i]/=peak;
    size_t pad=fft_n/2, frames=n/hop+1, bins_count=fft_n/2+1;
    if (frames>MAX_FRAMES) return -1;
    double padded[MAX_AUDIO+MAX_FFT];
    for(size_t i=0;i<pad;++i) padded[i]=audio[pad-i];
    for(size_t i=0;i<n;++i) padded[pad+i]=audio[i];
    for(size_t i=0;i<pad;++i) padded[pad+n+i]=audio[n-2-i];

    double freqs[MAX_MELS+2], bins_f[MAX_MELS+2]; size_t bins[MAX_MELS+2];
    double mel_lo=hz_to_mel(0.0), mel_hi=hz_to_mel((double)(sr/2));
    for(size_t i=0;i<mels+2;++i){double mel=mel_lo+(mel_hi-mel_lo)*(double)i/(double)(mels+1);freqs[i]=mel_to_hz(mel);bins_f[i]=floor((double)(fft_n+1)/(double)sr*freqs[i]);if(bins_f[i]<0.0||bins_f[i]>=(double)bins_count)return -1;bins[i]=(size_t)bins_f[i];}
    for(size_t i=0;i<mels+1;++i)if(bins[i]>=bins[i+1])return -1;
    double norms[MAX_MELS];
    for(size_t i=0;i<mels;++i){norms[i]=2.0/(freqs[i+2]-freqs[i]);if(!isfinite(norms[i]))return -1;}
    double logged[MAX_MELS][MAX_FRAMES];
    double win[MAX_FFT]; for(size_t i=0;i<fft_n;++i)win[i]=0.5-0.5*cos(2.0*PI*(double)i/(double)fft_n);
    for(size_t frame=0;frame<frames;++frame){
        double re[MAX_FFT],im[MAX_FFT];
        for(size_t i=0;i<fft_n;++i){re[i]=padded[frame*hop+i]*win[i];im[i]=0.0;}
        fft(re,im,fft_n);
        float power[MAX_FFT/2+1];
        for(size_t k=0;k<bins_count;++k){float r=(float)re[k],q=(float)im[k];float mag=hypotf(r,q);power[k]=mag*mag;}
        for(size_t f=0;f<mels;++f){
            size_t start=bins[f],mid=bins[f+1],end=bins[f+2];double energy=0.0;
            size_t rising=mid-start,falling=end-mid;
            for(size_t k=start;k<mid;++k){double w=rising==1?0.0:(double)(k-start)/(double)(rising-1);energy+=(double)power[k]*w;}
            for(size_t k=mid;k<end;++k){double w=falling==1?1.0:1.0-(double)(k-mid)/(double)(falling-1);energy+=(double)power[k]*w;}
            energy*=norms[f];if(!isfinite(energy)||energy<=0.0)return -1;logged[f][frame]=10.0*log10(energy);
        }
    }
    double result[MAX_DCTS][MAX_FRAMES];
    for(size_t d=0;d<dcts;++d){double scale=d==0?1.0/sqrt((double)mels):sqrt(2.0/(double)mels);for(size_t frame=0;frame<frames;++frame){double sum=0.0;for(size_t j=0;j<mels;++j){double basis=d==0?scale:scale*cos((double)d*(2.0*(double)j+1.0)*PI/(2.0*(double)mels));sum+=basis*logged[j][frame];}if(!isfinite(sum))return -1;result[d][frame]=sum;}}
    size_t bytes=dcts*frames*8;
    if(output==NULL||capacity<bytes)return -2;
    size_t pos=0;for(size_t d=0;d<dcts;++d)for(size_t frame=0;frame<frames;++frame){put_f64_le(output+pos,result[d][frame]);pos+=8;}
    return (int64_t)bytes;
}
