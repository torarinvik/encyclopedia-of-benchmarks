module nbench_fourier_coefficients;
import "math";
const usz MAX_N=16;
const double INVALID_RESULT=-1e300;
fn double term(double x,double omega,usz select){double base=math.pow(x+1.0,x);if(select==0)return base;if(select==1)return base*math.cos(omega*x);return base*math.sin(omega*x);}
fn double integrate(double omega,usz select){double x=0.0,dx=2.0/200.0,value=term(0.0,omega,select)/2.0;usz steps=200;if(steps!=1){steps-=1;while(true){steps-=1;if(steps==0)break;x+=dx;value+=term(x,omega,select);}}return(value+term(2.0,omega,select)/2.0)*dx;}
fn double nbench_fourier_coefficients(long* input,usz length) @export("nbench_fourier_coefficients"){
 if(input==null||length<1||length>2)return INVALID_RESULT;long raw=input[0];if(raw<1||raw>(long)MAX_N||length!=1)return INVALID_RESULT;usz n=(usz)raw;double[MAX_N] a;double[MAX_N] b;a[0]=integrate(0.0,0)/2.0;
 for(usz i=1;i<n;i+=1){double omega=3.1415926535897932*(double)i;a[i]=integrate(omega,1);b[i]=integrate(omega,2);}
 double checksum=0.0;for(usz i=0;i<n;i+=1)checksum+=(double)(i+1)*a[i];for(usz i=1;i<n;i+=1)checksum+=(double)i*b[i];if(checksum!=checksum||checksum>1.7976931348623157e308||checksum< -1.7976931348623157e308)return INVALID_RESULT;return checksum;
}
