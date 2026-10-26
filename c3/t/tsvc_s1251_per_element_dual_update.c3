module tsvc_s1251_per_element_dual_update;
extern fn double trunc(double x);
extern fn double fabs(double x);
fn long long tsvc_s1251_per_element_dual_update(double* x, usz l, double* y, usz c) @export("tsvc_s1251_per_element_dual_update") {
 if (x == null || l < 6 || l > 321) return -1;
 double r=x[0]; if (r!=r || trunc(r)!=r || r<1 || r>64) return -1;
 usz n=(usz)r; if(l!=1+5*n)return -1;
 for(usz i=1;i<l;i++)if(x[i]!=x[i]||trunc(x[i])!=x[i]||fabs(x[i])>1)return -1;
 if(y==null||c<2*n)return -2;
 double[64] a; double[64] b;
 for(usz i=0;i<n;i++){double saved=x[1+n+i]+x[1+2*n+i];b[i]=x[1+i]+x[1+3*n+i];a[i]=saved*x[1+4*n+i];}
 for(usz i=0;i<n;i++){y[i]=a[i];y[n+i]=b[i];}
 return (long long)(2*n);
}
