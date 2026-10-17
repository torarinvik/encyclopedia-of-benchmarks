module mfcc;

extern fn double cos(double x);
extern fn double sin(double x);
extern fn double pow(double x, double y);
extern fn double log10(double x);
extern fn double sqrt(double x);
extern fn double fabs(double x);
extern fn double nearbyint(double x);
extern fn double hypot(double x, double y);
extern fn double floor(double x);

const long MAX_AUDIO=2048, MAX_FFT=1024, MAX_FRAMES=257, MAX_MELS=16, MAX_DCTS=40;
const double PI=3.14159265358979323846264338327950288;

fn void fft(double[MAX_FFT] *re,double[MAX_FFT] *im,usz n){
    usz j=0;
    for(usz i=1;i<n;i++){usz bit=n>>1;while((j&bit)!=0){j^=bit;bit>>=1;}j^=bit;if(i<j){double t=re[i];re[i]=re[j];re[j]=t;t=im[i];im[i]=im[j];im[j]=t;}}
    for(usz len=2;len<=n;len<<=1){double angle=-2.0*PI/(double)len,sr=cos(angle),si=sin(angle);usz half=len>>1;for(usz start=0;start<n;start+=len){double wr=1.0,wi=0.0;for(usz k=0;k<half;k++){usz e=start+k,o=e+half;double tr=wr*re[o]-wi*im[o],ti=wr*im[o]+wi*re[o];re[o]=re[e]-tr;im[o]=im[e]-ti;re[e]+=tr;im[e]+=ti;double next=wr*sr-wi*si;wi=wr*si+wi*sr;wr=next;}}}
}
fn double hz_to_mel(double hz){return 2595.0*log10(1.0+hz/700.0);}
fn double mel_to_hz(double mel){return 700.0*(pow(10.0,mel/2595.0)-1.0);}

fn long mfcc(long *v,usz n,uint8 *out,usz cap) @export("mfcc") {
    if(v==null||n<6||n>2054)return -1;
    long n0=v[0],sr0=v[1],hm0=v[2],fn0=v[3],m0=v[4],d0=v[5];
    if(n0<33||n0>MAX_AUDIO||n!=(usz)n0+6||sr0<8000||sr0>48000||hm0<1||hm0>50)return -1;
    if(!(fn0==64||fn0==128||fn0==256||fn0==512||fn0==1024)||m0<2||m0>MAX_MELS||d0<1||d0>MAX_DCTS)return -1;
    usz count=(usz)n0,sr=(usz)sr0,fft_n=(usz)fn0,mels=(usz)m0,dcts=(usz)d0;
    if(count<fft_n/2+1)return -1;
    double hr=nearbyint((double)sr*(double)hm0/1000.0);if(hr<1.0)return -1;usz hop=(usz)hr;
    double[MAX_AUDIO] audio;double peak=0.0;
    for(usz i=0;i<count;i++){ulong bits=@bitcast(ulong,v[6+i]);double x=@bitcast(double,bits);if(x!=x||fabs(x)>1000000.0)return -1;audio[i]=x;if(fabs(x)>peak)peak=fabs(x);}
    if(peak==0.0)return -1;for(usz i=0;i<count;i++)audio[i]/=peak;
    usz pad=fft_n/2,frames=count/hop+1,nbins=fft_n/2+1;if(frames>MAX_FRAMES)return -1;
    double[MAX_AUDIO+MAX_FFT] padded;for(usz i=0;i<pad;i++)padded[i]=audio[pad-i];for(usz i=0;i<count;i++)padded[pad+i]=audio[i];for(usz i=0;i<pad;i++)padded[pad+count+i]=audio[count-2-i];
    double[MAX_MELS+2] freqs;usz[MAX_MELS+2] bins;double mel_hi=hz_to_mel((double)(sr/2));
    for(usz i=0;i<mels+2;i++){double mel=mel_hi*(double)i/(double)(mels+1);freqs[i]=mel_to_hz(mel);double b=floor((double)(fft_n+1)/(double)sr*freqs[i]);if(b<0.0||b>=(double)nbins)return -1;bins[i]=(usz)b;}
    for(usz i=0;i<mels+1;i++)if(bins[i]>=bins[i+1])return -1;
    double[MAX_MELS] norms;for(usz i=0;i<mels;i++){norms[i]=2.0/(freqs[i+2]-freqs[i]);if(norms[i]!=norms[i])return -1;}
    double[MAX_MELS][MAX_FRAMES] logged;double[MAX_FFT] win;for(usz i=0;i<fft_n;i++)win[i]=0.5-0.5*cos(2.0*PI*(double)i/(double)fft_n);
    for(usz frame=0;frame<frames;frame++){
        double[MAX_FFT] re,im;for(usz i=0;i<fft_n;i++){re[i]=padded[frame*hop+i]*win[i];im[i]=0.0;}fft(&re,&im,fft_n);
        float[MAX_FFT/2+1] power;for(usz k=0;k<nbins;k++){float r=(float)re[k],q=(float)im[k];float mag=(float)hypot((double)r,(double)q);power[k]=mag*mag;}
        for(usz f=0;f<mels;f++){usz start=bins[f],mid=bins[f+1],end=bins[f+2],rise=mid-start,fall=end-mid;double energy=0.0;for(usz k=start;k<mid;k++){double w=rise==1?0.0:(double)(k-start)/(double)(rise-1);energy+=(double)power[k]*w;}for(usz k=mid;k<end;k++){double w=fall==1?1.0:1.0-(double)(k-mid)/(double)(fall-1);energy+=(double)power[k]*w;}energy*=norms[f];if(energy<=0.0||energy!=energy)return -1;logged[f][frame]=10.0*log10(energy);}
    }
    double[MAX_DCTS][MAX_FRAMES] result;for(usz d=0;d<dcts;d++){double scale=d==0?1.0/sqrt((double)mels):sqrt(2.0/(double)mels);for(usz frame=0;frame<frames;frame++){double sum=0.0;for(usz j=0;j<mels;j++){double basis=d==0?scale:scale*cos((double)d*(2.0*(double)j+1.0)*PI/(2.0*(double)mels));sum+=basis*logged[j][frame];}if(sum!=sum)return -1;result[d][frame]=sum;}}
    usz bytes=dcts*frames*8;if(out==null||cap<bytes)return -2;usz pos=0;
    for(usz d=0;d<dcts;d++)for(usz f=0;f<frames;f++){ulong bits=@bitcast(ulong,result[d][f]);for(usz b=0;b<8;b++){out[pos++]=(uint8)(bits&255);bits>>=8;}}
    return (long)bytes;
}
