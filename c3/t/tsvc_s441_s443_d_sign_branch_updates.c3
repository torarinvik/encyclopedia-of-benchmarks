module tsvc_s441_s443_d_sign_branch_updates;
extern fn double trunc(double x);
extern fn double fabs(double x);
fn long long tsvc_s441_s443_d_sign_branch_updates(double* x,usz l,double* y,usz cap) @export("tsvc_s441_s443_d_sign_branch_updates"){
 if(x==null||l<7||l>259)return -1;double rm=x[0];double rn=x[1];double rp=x[2];
 if(rm!=rm||trunc(rm)!=rm||(rm!=0&&rm!=1)||rn!=rn||trunc(rn)!=rn||rn<1||rn>64||rp!=rp||trunc(rp)!=rp||rp<1||rp>8)return -1;
 usz mode=(usz)rm;usz n=(usz)rn;usz passes=(usz)rp;if(l!=3+4*n)return -1;
 for(usz i=3;i<l;i++)if(x[i]!=x[i]||trunc(x[i])!=x[i]||fabs(x[i])>1)return -1;
 if(y==null||cap<n)return -2;double[64] a;usz b=3+n;usz c=3+2*n;usz d=3+3*n;for(usz i=0;i<n;i++)a[i]=x[3+i];
 for(usz pass=0;pass<passes;pass++)for(usz i=0;i<n;i++){if(mode==0){if(x[d+i]<0)a[i]+=x[b+i]*x[c+i];else if(x[d+i]==0)a[i]+=x[b+i]*x[b+i];else a[i]+=x[c+i]*x[c+i];}else if(x[d+i]<=0)a[i]+=x[b+i]*x[c+i];else a[i]+=x[b+i]*x[b+i];}
 for(usz i=0;i<n;i++)y[i]=a[i];return (long long)n
}
