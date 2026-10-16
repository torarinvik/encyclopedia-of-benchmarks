module generalized_esd;
extern fn double sqrt(double);
extern fn double fabs(double);
const double[9] CRITICAL = {0,0,0,1.1543048513440384,1.48125,1.715037312343363,1.887145117783933,2.0199685076795957,2.126645087195462};
fn long generalized_esd(long* v, usz length) @export("generalized_esd") {
 if(v==null||length<5)return -1;long n=v[0]; long limit=v[1];if(n<3||n>8||limit<1||limit>3||limit>n-2||length!=(usz)n+2)return -1;
 double[8] x;int[8] idx;for(usz i=0;i<(usz)n;i++){if(v[i+2]<-10000||v[i+2]>10000)return -1;x[i]=(double)v[i+2];idx[i]=(int)i;}
 int remaining=(int)n; int accepted=0;int[3] removed;
 for(int step=1;step<=limit;step++){double mean=0;for(int i=0;i<remaining;i++)mean+=x[i];mean/=(double)remaining;double ss=0;for(int i=0;i<remaining;i++){double d=x[i]-mean;ss+=d*d;}double sd=sqrt(ss/(double)(remaining-1));if(sd==0)break;int worst=0;double largest=-1;for(int i=0;i<remaining;i++){double d=fabs(x[i]-mean);if(d>largest){largest=d;worst=i;}}removed[step-1]=idx[worst];if(largest/sd>CRITICAL[remaining])accepted=step;remaining--;x[worst]=x[remaining];idx[worst]=idx[remaining];}
 ulong mask=0;for(int i=0;i<accepted;i++)mask|=1UL<<removed[i];return (long)mask;
}
