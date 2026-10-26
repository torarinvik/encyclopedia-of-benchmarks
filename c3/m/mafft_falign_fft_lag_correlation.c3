// Clean-room bounded MAFFT Falign FFT lag profile; see package LICENSE.txt.
module mafft_falign_fft_lag_correlation;
extern fn double trunc(double value);
extern fn double cos(double value);
extern fn double sin(double value);
extern fn double sqrt(double value);
const long MAX_SEQUENCE = 32;
const double[20] POLARITY = {8.1,10.5,11.6,13.0,5.5,10.5,12.3,9.0,10.4,5.2,4.9,11.3,5.7,5.2,8.0,9.2,8.6,5.4,6.2,5.9};
const double[20] VOLUME = {31.0,124.0,56.0,54.0,55.0,85.0,83.0,3.0,96.0,111.0,111.0,119.0,105.0,132.0,32.5,32.0,61.0,170.0,136.0,84.0};

fn int amino_channel(long code) {
    if(code==65)return 0;if(code==82)return 1;if(code==78)return 2;if(code==68)return 3;if(code==67)return 4;
    if(code==81)return 5;if(code==69)return 6;if(code==71)return 7;if(code==72)return 8;if(code==73)return 9;
    if(code==76)return 10;if(code==75)return 11;if(code==77)return 12;if(code==70)return 13;if(code==80)return 14;
    if(code==83)return 15;if(code==84)return 16;if(code==87)return 17;if(code==89)return 18;if(code==86)return 19;return -1;
}
fn void fft(double* re,double* im,usz offset,usz n,bool inverse) {
    usz j=0;for(usz i=1;i<n;i++){usz bit=n>>1;while((j&bit)!=0){j^=bit;bit>>=1;}j^=bit;if(i<j){double t=re[offset+i];re[offset+i]=re[offset+j];re[offset+j]=t;t=im[offset+i];im[offset+i]=im[offset+j];im[offset+j]=t;}}
    for(usz span=2;span<=n;span*=2){double angle=(inverse?1.0:-1.0)*6.2831853071795864769/(double)span;double cr=cos(angle),ci=sin(angle);for(usz start=0;start<n;start+=span){double wr=1.0,wi=0.0;for(usz k=0;k<span/2;k++){usz u=offset+start+k,v=u+span/2;double pr=wr*re[v]-wi*im[v],pi=wr*im[v]+wi*re[v],ur=re[u],ui=im[u];re[u]=ur+pr;im[u]=ui+pi;re[v]=ur-pr;im[v]=ui-pi;double nw=wr*cr-wi*ci;wi=wr*ci+wi*cr;wr=nw;}}}
    if(!inverse)for(usz q=0;q<n;q++){re[offset+q]/=(double)n;im[offset+q]/=(double)n;}
}
fn long mafft_falign_fft_lag_correlation(double* input,usz length,double* output,usz capacity) @export("mafft_falign_fft_lag_correlation") {
    if(input==null||length<4||length>66)return -1;
    for(usz q=0;q<length;q++){double v=input[q];if(v!=v||trunc(v)!=v)return -1;}
    if(input[0]<1||input[0]>MAX_SEQUENCE||input[1]<1||input[1]>MAX_SEQUENCE)return -1;
    usz n1=(usz)input[0],n2=(usz)input[1];if(length!=2+n1+n2)return -1;
    for(usz q=2;q<length;q++)if(input[q]<65.0||input[q]>90.0||amino_channel((long)input[q])<0)return -1;
    usz n=1;usz longer=n1>n2?n1:n2;while(n<=longer)n*=2;if(output==null||capacity<n)return -2;
    double[1280] r1;double[1280] i1;double[1280] r2;double[1280] i2;double[64] re;double[64] im;
    for(usz q=0;q<1280;q++){r1[q]=0;i1[q]=0;r2[q]=0;i2[q]=0;}for(usz q=0;q<64;q++){re[q]=0;im[q]=0;}
    double mp=0.0,mv=0.0;for(usz ch=0;ch<20;ch++){mp+=POLARITY[ch];mv+=VOLUME[ch];}mp/=20.0;mv/=20.0;
    double vp=0.0,vv=0.0;for(usz ch=0;ch<20;ch++){double dp=POLARITY[ch]-mp,dv=VOLUME[ch]-mv;vp+=dp*dp;vv+=dv*dv;}double sp=sqrt(vp/20.0),sv=sqrt(vv/20.0);
    for(usz p=0;p<n1;p++){usz ch=(usz)amino_channel((long)input[2+p]);r1[p]=(POLARITY[ch]-mp)/sp;i1[p]=(VOLUME[ch]-mv)/sv;}
    for(usz p=0;p<n2;p++){usz ch=(usz)amino_channel((long)input[2+n1+p]);r2[p]=(POLARITY[ch]-mp)/sp;i2[p]=(VOLUME[ch]-mv)/sv;}
    fft(&r1[0],&i1[0],0,n,false);fft(&r2[0],&i2[0],0,n,false);
    for(usz k=0;k<n;k++){re[k]=r1[k]*r2[k]+i1[k]*i2[k];im[k]=-r1[k]*i2[k]+i1[k]*r2[k];}
    fft(&re[0],&im[0],0,n,true);for(usz q=0;q<n;q++)output[q]=re[(n/2+n-q)%n];return (long)n;
}
