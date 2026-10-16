module maclaurin;
extern fn double pow(double base, double exponent);
extern fn double fabs(double value);
const double BAD = -1.0e300;
fn double fact(long n){double f=1.0;for(long i=2;i<=n;i++)f*= (double)i;return f;}
fn double term(long m,double x,long i){long e;double sign=1.0;if(m==0)e=i;else if(m==1){e=2*i+1;if(i%2)sign=-1.0;}else{e=2*i;if(i%2)sign=-1.0;}return m==0?pow(x,(double)e)/fact(e):sign/fact(e)*pow(x,(double)e);}
fn double maclaurin(long* v,usz n) @export("maclaurin") {if(v==null||n!=3)return BAD;long m=v[0],xm=v[1],em=v[2];if(m<0||m>2||xm < -2000||xm>2000||em<1||em>250)return BAD;double x=(double)xm/1000.0,error=(double)em/1000.0,coefficient=0.0,result=0.0;for(long i=0;i<32;i++){result+=coefficient;coefficient=term(m,x,i);if(fabs(coefficient)<=error)return result;}return BAD;}
