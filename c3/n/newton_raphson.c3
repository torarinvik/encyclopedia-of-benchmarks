module newton_raphson;
const double INVALID_RESULT = -1.0e300;
fn double newton_raphson(long* values, usz length) @export("newton_raphson") {
    if(values==null || length!=2)return INVALID_RESULT;
    long n=values[0]; long q=values[1]; if(n<2||n>4||q<4||q>8)return INVALID_RESULT;
    double x=(double)q/4.0; for(int i=0;i<8;i++)x=0.5*(x+(double)n/x); return x;
}
