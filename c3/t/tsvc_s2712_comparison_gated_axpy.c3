module tsvc_s2712_comparison_gated_axpy;
extern fn double trunc(double x);
extern fn double fabs(double x);
fn long long tsvc_s2712_comparison_gated_axpy(double* x,usz l,double* y,usz cap) @export("tsvc_s2712_comparison_gated_axpy"){
 if(x==null||l<5||l>194)return -1;double rn=x[0];double rp=x[1];if(rn!=rn||trunc(rn)!=rn||rn<1||rn>64||rp!=rp||trunc(rp)!=rp||rp<1||rp>8)return -1;usz n=(usz)rn;usz passes=(usz)rp;if(l!=2+3*n)return -1
 for(usz i=2;i<l;i++)if(x[i]!=x[i]||trunc(x[i])!=x[i]||fabs(x[i])>2)return -1
 if(y==null||cap<n)return -2;double[64] a;for(usz i=0;i<n;i++)a[i]=x[2+i]
 for(usz pass=0;pass<passes;pass++)for(usz i=0;i<n;i++){double b=x[2+n+i];if(a[i]>b)a[i]+=b*x[2+2*n+i];}
 for(usz i=0;i<n;i++)y[i]=a[i];return (long long)n
}
