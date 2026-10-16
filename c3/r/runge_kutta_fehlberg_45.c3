module runge_kutta_fehlberg_45;
const double INVALID=-1.0e300;
fn bool finite(double value){return value==value&&value> -1.0e300&&value<1.0e300;}
fn double deriv(long id,double x,double y){if(id==0)return y;if(id==1)return x;if(id==2)return x+y;if(id==3)return(x-y)/2.0;return 1.0+y*y;}
fn bool step(long id,double x,double y,double h,double* out){
    double k1=h*deriv(id,x,y),k2=h*deriv(id,x+h/4.0,y+k1/4.0),k3=h*deriv(id,x+(3.0/8.0)*h,y+(3.0/32.0)*k1+(9.0/32.0)*k2);
    double k4=h*deriv(id,x+(12.0/13.0)*h,y+(1932.0/2197.0)*k1-(7200.0/2197.0)*k2+(7296.0/2197.0)*k3);
    double k5=h*deriv(id,x+h,y+(439.0/216.0)*k1-8.0*k2+(3680.0/513.0)*k3-(845.0/4104.0)*k4);
    double k6=h*deriv(id,x+h/2.0,y-(8.0/27.0)*k1+2.0*k2-(3544.0/2565.0)*k3+(1859.0/4104.0)*k4-(11.0/40.0)*k5);
    *out=y+(16.0/135.0)*k1+(6656.0/12825.0)*k3+(28561.0/56430.0)*k4-(9.0/50.0)*k5+(2.0/55.0)*k6;
    return finite(k1)&&finite(k2)&&finite(k3)&&finite(k4)&&finite(k5)&&finite(k6)&&finite(*out);
}
fn double runge_kutta_fehlberg_45(long* v,ulong n) @export("runge_kutta_fehlberg_45") {
    if(v==null||n!=5)return INVALID;long id=v[0],ym=v[1],xm=v[2],hm=v[3],em=v[4];
    if(id<0||id>4||ym< -1000000||ym>1000000||xm< -1000000||xm>1000000||em< -1000000||em>1000000||hm<10000||hm>250000||em<=xm)return INVALID;
    double y=(double)ym/1000000.0,x=(double)xm/1000000.0,h=(double)hm/1000000.0,end=(double)em/1000000.0;
    if(id==4&&(x<0.0||y>0.0))return INVALID;int steps=(int)((end-x)/h);if(steps<1||steps>64)return INVALID;
    for(int i=0;i<steps;i++){double next;if(!step(id,x,y,h,&next))return INVALID;y=next;x=h+x;if(!finite(x))return INVALID;}return y;
}
