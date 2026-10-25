module cbench_rsynth_impulsive_glottal;

extern fn double exp(double value);
extern fn double cos(double value);

fn long cbench_rsynth_impulsive_glottal_sample(double* input, usz n, double* output, usz cap) @export("cbench_rsynth_impulsive_glottal_sample") {
    if(input==null||n==0||n>3)return -1;
    for(usz i=0;i<n;i++)if(input[i]!=input[i]||input[i]>1.0e300||input[i]<-1.0e300)return -1;
    if(n!=2||input[0]<40||input[0]>263||input[0]!=(double)(long)input[0]||input[1]<0||input[1]>299||input[1]!=(double)(long)input[1])return -1;
    long open=(long)input[0],target=(long)input[1],rate=8000;
    float minus_pi=(float)(-3.14159265358979323846/(double)rate);float two_pi=(float)(-2.0*(double)minus_pi);long bw=rate/open;
    float r=(float)exp((double)minus_pi*(double)bw);float c=-(r*r);float b=(float)((double)r*cos((double)two_pi*0.0)*2.0);
    float a=(float)(1.0-(double)b-(double)c);float t=(float)((double)open*0.00833);a=(float)(a*(t*t));
    float p1=0.0,p2=0.0,result=0.0;
    for(long i=0;i<=target;i++){float impulse=i==1?13000000.0:(i==2?-13000000.0:0.0);float x=(float)(a*impulse);x=(float)(x+(float)(b*p1));x=(float)(x+(float)(c*p2));p2=p1;p1=x;result=x;}
    if(output==null||cap<1)return -2;output[0]=(double)result;return 1;
}
