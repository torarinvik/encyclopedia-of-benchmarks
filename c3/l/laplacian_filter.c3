module laplacian_filter;
fn double laplacian_filter(long *v, usz n) @export("laplacian_filter") { if(n!=9)return -1.0e300; for(usz i=0;i<n;i++)if(v[i]<0||v[i]>255)return -1.0e300; return (double)(4*v[4]-v[1]-v[3]-v[5]-v[7]); }
