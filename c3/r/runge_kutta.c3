module runge_kutta;
extern fn double ceil(double value);
const double INVALID = -1.0e300;
fn bool finite(double value) { return value == value && value > -1.0e300 && value < 1.0e300; }
fn double deriv(long id,double x,double y){if(id==0)return y;if(id==1)return x;if(id==2)return x+y;if(id==3)return(x-y)/2.0;return 1.0+y*y;}
fn bool step(long id,double x,double y,double h,double* out){double k1=deriv(id,x,y),k2=deriv(id,x+0.5*h,y+0.5*h*k1),k3=deriv(id,x+0.5*h,y+0.5*h*k2),k4=deriv(id,x+h,y+h*k3);*out=y+(1.0/6.0)*h*(k1+2.0*k2+2.0*k3+k4);return finite(k1)&&finite(k2)&&finite(k3)&&finite(k4)&&finite(*out);}
fn double runge_kutta(long* v,ulong n) @export("runge_kutta") {
    if(v==null||n!=5)return INVALID;long id=v[0],ym=v[1],xm=v[2],hm=v[3],em=v[4];
    if(id<0||id>4||ym< -1000000||ym>1000000||xm< -1000000||xm>1000000||em< -1000000||em>1000000||hm<10000||hm>250000||em<=xm)return INVALID;
    double y=(double)ym/1000000.0,x=(double)xm/1000000.0,h=(double)hm/1000000.0,end=(double)em/1000000.0;
    if(id==4&&(x<0.0||y>0.0))return INVALID;int steps=(int)ceil((end-x)/h);if(steps<1||steps>64)return INVALID;
    for(int i=0;i<steps;i++){double next;if(!step(id,x,y,h,&next))return INVALID;y=next;x+=h;if(!finite(x))return INVALID;}return y;
}
