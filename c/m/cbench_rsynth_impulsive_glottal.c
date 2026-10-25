#include <math.h>
#include <stddef.h>
#include <stdint.h>

int64_t cbench_rsynth_impulsive_glottal_sample(const double *input,size_t n,double *output,size_t cap){
    if(input==NULL||n==0||n>3)return -1;
    for(size_t i=0;i<n;i++)if(!isfinite(input[i]))return -1;
    if(n!=2||input[0]<40||input[0]>263||trunc(input[0])!=input[0]||input[1]<0||input[1]>299||trunc(input[1])!=input[1])return -1;
    const long nopen=(long)input[0], target=(long)input[1], sample_rate=8000;
    const float minus_pi_t=(float)(-3.14159265358979323846264338327950288/sample_rate);
    const float two_pi_t=(float)(-2.0*(double)minus_pi_t);
    const long bandwidth=sample_rate/nopen;
    const float r=(float)exp((double)minus_pi_t*(double)bandwidth);
    const float c=-(r*r);
    const float b=(float)((double)r*cos((double)two_pi_t*0.0)*2.0);
    float a=(float)(1.0-(double)b-(double)c);
    const float temp1=(float)((double)nopen*0.00833);
    a=(float)(a*(temp1*temp1));
    float p1=0.0f,p2=0.0f,result=0.0f;
    for(long i=0;i<=target;i++){
        const float impulse=i==0?0.0f:(i==1?13000000.0f:(i==2?-13000000.0f:0.0f));
        float x=(float)(a*impulse);
        x=(float)(x+(float)(b*p1));
        x=(float)(x+(float)(c*p2));
        p2=p1;p1=x;result=x;
    }
    if(output==NULL||cap<1)return -2;
    output[0]=(double)result;return 1;
}
