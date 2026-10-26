module tsvc_s2251_carried_scalar_expansion;
extern fn double trunc(double value);
extern fn double fabs(double value);
fn long tsvc_s2251_carried_scalar_expansion(double* x,usz l,double* y,usz cap) @export("tsvc_s2251_carried_scalar_expansion"){if(x==null||l<6||l>321)return -1;double r=x[0];if(r!=r||trunc(r)!=r||r<1||r>64)return -1;usz n=(usz)r;if(l!=1+5*n)return -1;for(usz i=1;i<l;i++)if(x[i]!=x[i]||trunc(x[i])!=x[i]||fabs(x[i])>1)return -1;if(y==null||cap<2*n)return -2;double[64] a;double[64] b;double s=0;for(usz i=0;i<n;i++){a[i]=s*x[1+4*n+i];s=x[1+n+i]+x[1+2*n+i];b[i]=a[i]+x[1+3*n+i];}for(usz i=0;i<n;i++){y[i]=a[i];y[n+i]=b[i];}return (long)(2*n);}
