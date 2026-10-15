module linear_regression_stochastic_gradient_descent;
const double INVALID=-1.0e300;
fn double linear_regression_stochastic_gradient_descent_impl(long* v,usz length){
 if(v==null||length<9||length>133)return INVALID;long n=v[0],epochs=v[1],rate=v[2],m0=v[3],b0=v[4];
 if(n<2||n>64||length!=(usz)(5+2*n)||epochs<1||epochs>200||rate<1||rate>10000||m0< -10000000||m0>10000000||b0< -10000000||b0>10000000)return INVALID;
 for(usz i=0;i<(usz)n;i++){long x=v[5+2*i],y=v[6+2*i];if(x< -10000000||x>10000000||y< -100000000||y>100000000)return INVALID;}
 double alpha=(double)rate/1000000.0,w=(double)m0/1000000.0,b=(double)b0/1000000.0;
 for(long epoch=0;epoch<epochs;epoch++)for(long i=0;i<n;i++){double x=(double)v[5+2*i]/1000000.0,y=(double)v[6+2*i]/1000000.0,error=w*x+b-y;w-=alpha*(error*x/(double)n);b-=alpha*(error/(double)n);}
 return w;
}
fn double linear_regression_stochastic_gradient_descent(long* v,usz length) @export("linear_regression_stochastic_gradient_descent"){return linear_regression_stochastic_gradient_descent_impl(v,length);}
