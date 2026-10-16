module runge_kutta_gills;
extern fn double sqrt(double value);
const double INVALID=-1.0e300;
fn bool finite(double value){return value==value&&value> -1.0e300&&value<1.0e300;}
fn double deriv(long id,double x,double y){if(id==0)return y;if(id==1)return x;if(id==2)return x+y;if(id==3)return(x-y)/2.0;return 1.0+y*y;}
fn bool step(long id,double x,double y,double h,double* out){double s=sqrt(2.0),k1=h*deriv(id,x,y),k2=h*deriv(id,x+h/2.0,y+k1/2.0),k3=h*deriv(id,x+h/2.0,y+(-0.5+1.0/s)*k1+(1.0-1.0/s)*k2),k4=h*deriv(id,x+h,y-(1.0/s)*k2+(1.0+1.0/s)*k3);*out=y+(k1+(2.0-s)*k2+(2.0+s)*k3+k4)/6.0;return finite(k1)&&finite(k2)&&finite(k3)&&finite(k4)&&finite(*out);}
fn double runge_kutta_gills(long* v,ulong n) @export("runge_kutta_gills") {
    if(v==null||n!=5)return INVALID;long id=v[0],ym=v[1],xm=v[2],hm=v[3],em=v[4];
    if(id<0||id>4||ym< -1000000||ym>1000000||xm< -1000000||xm>1000000||em< -1000000||em>1000000||hm<10000||hm>250000||em<=xm)return INVALID;
    double y=(double)ym/1000000.0,x=(double)xm/1000000.0,h=(double)hm/1000000.0,end=(double)em/1000000.0;
    if(id==4&&(x<0.0||y>0.0))return INVALID;int steps=(int)((end-x)/h);if(steps<1||steps>64)return INVALID;
    for(int i=0;i<steps;i++){double next;if(!step(id,x,y,h,&next))return INVALID;y=next;x+=h;if(!finite(x))return INVALID;}return y;
}
