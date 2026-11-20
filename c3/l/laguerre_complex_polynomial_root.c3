module laguerre_complex_polynomial_root;

extern fn double sqrt(double value);

struct C { double re; double im; }
const long BAD_FIELD = -9999999999;
fn C cadd(C a,C b){return {a.re+b.re,a.im+b.im};}
fn C csub(C a,C b){return {a.re-b.re,a.im-b.im};}
fn C cmul(C a,C b){return {a.re*b.re-a.im*b.im,a.re*b.im+a.im*b.re};}
fn C cdiv(C a,C b){double d=b.re*b.re+b.im*b.im;return {(a.re*b.re+a.im*b.im)/d,(a.im*b.re-a.re*b.im)/d};}
fn double cmag(C a){return sqrt(a.re*a.re+a.im*a.im);}
fn bool finite(double x){return x==x&&x<=1.0e308&&x>= -1.0e308;}
fn bool finitec(C a){return finite(a.re)&&finite(a.im);}
fn C csqrt(C a){double m=cmag(a);double re=sqrt((m+a.re)*0.5);double im=sqrt((m-a.re)*0.5);if(re!=re)re=0.0;if(im!=im)im=0.0;if(a.im<0.0)im = -im;return {re,im};}
fn long integer_field(double x,long lo,long hi){
    if(!finite(x)||x<(double)lo||x>(double)hi)return BAD_FIELD;
    long value=(long)x;if((double)value!=x)return BAD_FIELD;return value;
}
fn void evaluate(double* a,long n,C z,C* p,C* dp,C* ddp,double* scale){
    *p={a[n],0.0};*dp={0.0,0.0};*ddp={0.0,0.0};
    long k=n;while(k>0){k-=1;*ddp=cadd(cmul(*ddp,z),{2.0*dp->re,2.0*dp->im});*dp=cadd(cmul(*dp,z),*p);*p=cadd(cmul(*p,z),{a[k],0.0});}
    double radius=cmag(z);*scale=abs(a[n]);k=n;while(k>0){k-=1;*scale=*scale*radius+abs(a[k]);}
}
fn long solve(double* a,long n,C z,double tolerance,long iterations,double* out){
    long step=0;while(step<=iterations){
        if(!finitec(z))return -3;
        C p,dp,ddp;double scale;evaluate(a,n,z,&p,&dp,&ddp,&scale);
        if(!finitec(p)||!finitec(dp)||!finitec(ddp)||!finite(scale))return -3;
        if(cmag(p)<=tolerance*(scale>1.0?scale:1.0)){out[0]=z.re;out[1]=z.im;return 2;}
        if(step==iterations||(p.re==0.0&&p.im==0.0))return -3;
        C g=cdiv(dp,p);C h=csub(cmul(g,g),cdiv(ddp,p));
        C rad=cmul({(double)(n-1),0.0},csub(cmul({(double)n,0.0},h),cmul(g,g)));
        if(!finitec(g)||!finitec(h)||!finitec(rad))return -3;
        C root=csqrt(rad);C plus=cadd(g,root);C minus=csub(g,root);C den=cmag(plus)>=cmag(minus)?plus:minus;
        double dm=cmag(den);if(dm==0.0||!finite(dm))return -3;
        C correction=cdiv({(double)n,0.0},den);if(!finitec(correction))return -3;
        z=csub(z,correction);step+=1;
    }
    return -3;
}
fn long laguerre_complex_polynomial_root_impl(double* input,usz length,double* output){
    if(input==null||length<1||length>13)return -1;
    long n=integer_field(input[0],2,6);if(n==BAD_FIELD||length!=(usz)n+6)return -1;
    double[7] a={};
    for(long i=0;i<=n;i++){long value=integer_field(input[1+i],-16,16);if(value==BAD_FIELD)return -1;a[i]=(double)value;}
    if(a[n]==0.0)return -1;
    long re=integer_field(input[n+2],-4000,4000),im=integer_field(input[n+3],-4000,4000);
    long tol=integer_field(input[n+4],1,1000),iterations=integer_field(input[n+5],8,128);
    if(re==BAD_FIELD||im==BAD_FIELD||tol==BAD_FIELD||iterations==BAD_FIELD)return -1;
    return solve(&a[0],n,{(double)re/1000.0,(double)im/1000.0},(double)tol/1000000.0,iterations,output);
}
fn long laguerre_complex_polynomial_root(double* input,usz input_length,double* output,usz output_capacity) @export("laguerre_complex_polynomial_root") {
    if(input==null||input_length<1||input_length>13)return -1;
    long n=integer_field(input[0],2,6);if(n==BAD_FIELD||input_length!=(usz)n+6)return -1;
    for(long i=1;i<=n+5;i++)if(!finite(input[i]))return -1;
    // Decode every bounded field before checking the output view.
    for(long i=1;i<=n+1;i++)if(integer_field(input[i],-16,16)==BAD_FIELD)return -1;
    if(input[n+1]==0.0)return -1;
    if(integer_field(input[n+2],-4000,4000)==BAD_FIELD||integer_field(input[n+3],-4000,4000)==BAD_FIELD||integer_field(input[n+4],1,1000)==BAD_FIELD||integer_field(input[n+5],8,128)==BAD_FIELD)return -1;
    if(output==null||output_capacity<2)return -2;
    double[2] staged={};long status=laguerre_complex_polynomial_root_impl(input,input_length,&staged[0]);
    if(status!=2)return status;output[0]=staged[0];output[1]=staged[1];return 2;
}
