module dormand_prince_54_adaptive_ode;

extern fn double sin(double value);
extern fn double pow(double base, double exponent);

const usz MAX_INPUT_LENGTH = 7;

fn bool integer_field(double x, long lo, long hi, long* decoded) {
    if (!(x == x) || x < (double)lo || x > (double)hi || x != (double)(long)x) return false;
    *decoded = (long)x;
    return true;
}
fn bool finite_value(double x) { return x == x && x <= 1e300 && x >= -1e300; }
fn double rhs(long id, double x, double y) {
    if (id == 0) return y;
    if (id == 1) return x+y;
    if (id == 2) return sin(x);
    return 1.0;
}
fn bool trial(long id,double x,double y,double h,double k1,double* y5,double* error,double* k7) {
    double k2=rhs(id,x+h*(1.0/5.0),y+h*((1.0/5.0)*k1));
    double k3=rhs(id,x+h*(3.0/10.0),y+h*((3.0/40.0)*k1+(9.0/40.0)*k2));
    double k4=rhs(id,x+h*(4.0/5.0),y+h*((44.0/45.0)*k1-(56.0/15.0)*k2+(32.0/9.0)*k3));
    double k5=rhs(id,x+h*(8.0/9.0),y+h*((19372.0/6561.0)*k1-(25360.0/2187.0)*k2+(64448.0/6561.0)*k3-(212.0/729.0)*k4));
    double k6=rhs(id,x+h,y+h*((9017.0/3168.0)*k1-(355.0/33.0)*k2+(46732.0/5247.0)*k3+(49.0/176.0)*k4-(5103.0/18656.0)*k5));
    *y5=y+h*((35.0/384.0)*k1+(500.0/1113.0)*k3+(125.0/192.0)*k4-(2187.0/6784.0)*k5+(11.0/84.0)*k6);
    *k7=rhs(id,x+h,*y5);
    *error=h*((71.0/57600.0)*k1-(71.0/16695.0)*k3+(71.0/1920.0)*k4-(17253.0/339200.0)*k5+(22.0/525.0)*k6-(1.0/40.0)* *k7);
    return finite_value(*y5)&&finite_value(*error)&&finite_value(*k7);
}
fn long integrate(long id,double y,double x,double ending,long exponent,long attempts,double* result) {
    double tolerance=pow(10.0,-(double)exponent);
    double h=(ending-x)/4.0;
    if(h>0.25) h=0.25;
    double k1=rhs(id,x,y);
    for(long attempt=0;attempt<attempts;attempt++) {
        double remaining=ending-x;
        if(remaining<=0.0){*result=y;return 1;}
        double step=h;
        if(step>0.25) step=0.25;
        if(step>remaining) step=remaining;
        if(step<=0.0||x+step==x)return -3;
        double y5,error,k7;
        if(!trial(id,x,y,step,k1,&y5,&error,&k7))return -3;
        double abs_y=y<0.0?-y:y;
        double abs_y5=y5<0.0?-y5:y5;
        if(abs_y5>abs_y)abs_y=abs_y5;
        double scale=tolerance*(1.0+abs_y);
        double norm=(error<0.0?-error:error)/scale;
        if(!finite_value(norm))return -3;
        if(norm<=1.0){if(step==remaining)x=ending;else x+=step;y=y5;k1=k7;if(x>=ending){*result=y;return finite_value(y)?1:-3;}}
        double factor=norm==0.0?5.0:0.9*pow(norm,-0.2);
        if(factor<0.2)factor=0.2;
        if(factor>5.0)factor=5.0;
        h=step*factor;
    }
    return -3;
}

fn long dormand_prince_54_adaptive_ode(double* input,usz input_length,double* output,usz output_capacity)
    @export("dormand_prince_54_adaptive_ode") {
    if(input==null||input_length!=6||input_length>MAX_INPUT_LENGTH)return -1L;
    long id,ym,xm,em,exponent,attempts;
    if(!integer_field(input[0],0,3,&id)||!integer_field(input[1],-1000,1000,&ym)||
       !integer_field(input[2],-1000,1000,&xm)||!integer_field(input[3],-1000,1000,&em)||
       !integer_field(input[4],8,9,&exponent)||!integer_field(input[5],64,128,&attempts)||em<=xm)return -1L;
    if(output==null||output_capacity<1)return -2L;
    double result;
    long status=integrate(id,(double)ym/1000.0,(double)xm/1000.0,(double)em/1000.0,exponent,attempts,&result);
    if(status!=1||!finite_value(result))return -3L;
    output[0]=result;
    return 1L;
}
