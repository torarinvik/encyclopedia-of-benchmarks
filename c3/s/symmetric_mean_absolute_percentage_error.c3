module symmetric_mean_absolute_percentage_error;
extern fn double log(double value);
extern fn double log1p(double value);
extern fn double fabs(double value);
const double INVALID_RESULT=-1.0e300; const double SCALE=1000000.0;
fn double symmetric_mean_absolute_percentage_error(long* values, usz length) @export("symmetric_mean_absolute_percentage_error") {
    if(values==null || length<1)return INVALID_RESULT; long n=values[0]; if(n<1||n>64||length!=1+2*(usz)n)return INVALID_RESULT;
    for(usz i=0;i<2*(usz)n;i++)if(values[1+i]< -1000000||values[1+i]>1000000)return INVALID_RESULT;
    double total=0.0;for(usz i=0;i<(usz)n;i++){double t=(double)values[1+i]/SCALE,p=(double)values[1+(usz)n+i]/SCALE;double d=(fabs(t)+fabs(p))/2.0; if(d==0.0)d=1e-15; total+=fabs(t-p)/d;}return total/(double)n;
}
