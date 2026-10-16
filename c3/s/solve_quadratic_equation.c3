module solve_quadratic_equation;
extern fn double sqrt(double value);
const long LIMIT=1000000;
fn void put_f64_le(double value,char* output,usz offset){ulong bits=@bitcast(ulong,value);for(usz b=0;b<8;b++)output[offset+b]=(char)((bits>>(8*b))&255);}
fn long solve_quadratic_equation(long* values,usz length,char* output,usz capacity) @export("solve_quadratic_equation") {
    if(values==null||length!=2)return -1;long pi=values[0],qi=values[1];if(pi < -LIMIT||pi>LIMIT||qi < -LIMIT||qi>LIMIT)return -1;
    double p=(double)pi,q=(double)qi,root=sqrt(p*p/4.0-q);if(root!=root)return 0;
    double x1=-p/2.0-root,x2=-p/2.0+root;
    if(x1==x2){if(output==null||capacity<8)return -2;put_f64_le(x1,output,0);return 1;}
    if(output==null||capacity<16)return -2;put_f64_le(x1,output,0);put_f64_le(x2,output,8);return 2;
}
