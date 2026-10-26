module tsvc_s242_fused_prefix_update;
extern fn double trunc(double value);
extern fn double fabs(double value);
fn long tsvc_s242_fused_prefix_update(double* x,usz l,double* y,usz cap) @export("tsvc_s242_fused_prefix_update"){if(x==null||l<7||l>259)return -1;double r=x[0];if(r!=r||trunc(r)!=r||r<1||r>64)return -1;usz n=(usz)r;if(l!=3+4*n)return -1;for(usz i=1;i<l;i++)if(x[i]!=x[i]||trunc(x[i])!=x[i]||fabs(x[i])>1)return -1;if(y==null||cap<n)return -2;double[64] a;for(usz i=0;i<n;i++)a[i]=x[3+i];for(usz i=1;i<n;i++){double v=a[i-1]+x[1];v=v+x[2];v=v+x[3+2*n+i];v=v+x[3+3*n+i];v=v+x[3+4*n+i];a[i]=v;}for(usz i=0;i<n;i++)y[i]=a[i];return (long)n;}
