module integral_approximation;
const double INVALID_RESULT=-1.0e300;
fn double sample(long id,double x){if(id==0)return x*x;return x*x*x-x*x+378.0;}
fn double integral_approximation(long *v,usz n) @export("integral_approximation"){if(v==null||n!=4)return INVALID_RESULT;long id=v[0],li=v[1],ui=v[2],di=v[3];if(id<0||id>1||li<0||ui>32||li>=ui||di<1||di>8)return INVALID_RESULT;double lo=(double)li/8.0,hi=(double)ui/8.0,d=(double)di/8.0;usz count=(usz)((hi-lo)/d);if(count>32)return INVALID_RESULT;double total=0.0;for(usz i=0;i<count;i++){double begin=lo+(double)i*d;double end=lo+(double)(i+1)*d;total+=d*(sample(id,begin)+sample(id,end))/2.0;}return total;}
