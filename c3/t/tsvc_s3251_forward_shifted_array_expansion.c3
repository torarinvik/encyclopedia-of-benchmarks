module tsvc_s3251_forward_shifted_array_expansion;
extern fn double trunc(double x);
extern fn double fabs(double x);
fn long long tsvc_s3251_forward_shifted_array_expansion(double* x,usz l,double* y,usz cap) @export("tsvc_s3251_forward_shifted_array_expansion"){
 if(x==null||l<6||l>321)return -1;double r=x[0];if(r!=r||trunc(r)!=r||r<1||r>64)return -1;usz n=(usz)r;if(l!=1+5*n)return -1
 for(usz i=1;i<l;i++)if(x[i]!=x[i]||trunc(x[i])!=x[i]||fabs(x[i])>1)return -1
 if(y==null||cap<3*n)return -2;double[64] a;double[64] b;double[64] d
 for(usz i=0;i<n;i++){a[i]=x[1+i];b[i]=x[1+n+i];d[i]=x[1+3*n+i];}
 for(usz i=0;i+1<n;i++){a[i+1]=b[i]+x[1+2*n+i];b[i]=x[1+2*n+i]*x[1+4*n+i];d[i]=a[i]*x[1+4*n+i];}
 for(usz i=0;i<n;i++){y[i]=a[i];y[n+i]=b[i];y[2*n+i]=d[i];}return (long long)(3*n);
}
