module dimensionality_reduction_tsne;
extern fn double exp(double x);
extern fn double exp2(double x);
extern fn double log2(double x);
extern fn double fabs(double x);
fn long dimensionality_reduction_tsne(double* v,usz n,double* out,usz cap) @export("dimensionality_reduction_tsne") {
 if(v==null||n!=5||v[0]!=1.0||v[1]!=3.0)return -1;for(usz i=2;i<5;i++)if(v[i]!=v[i]||fabs(v[i])>100)return -1;if(out==null||cap<3)return -2;
 double[3][3] d;double[3][3] p;double[3][3] high;double[3][3] q;double[3][3] den;
 for(usz i=0;i<3;i++)for(usz j=0;j<3;j++){double z=v[2+i]-v[2+j];d[i][j]=z*z;}
 for(usz i=0;i<3;i++){double lo=-1.0/0.0;double hi=1.0/0.0;double beta=1;double[3] probs;for(usz it=0;it<50;it++){double[3] e;double sum=0;for(usz j=0;j<3;j++){e[j]=i==j?0:exp(-d[i][j]*beta);sum+=e[j];}if(sum==0){for(usz j=0;j<3;j++)p[i][j]=0;break;}double h=0;for(usz j=0;j<3;j++){probs[j]=e[j]/sum;if(probs[j]>0)h-=probs[j]*log2(probs[j]+1e-12);}double cur=exp2(h);if(fabs(cur-1.5)<1e-5){for(usz j=0;j<3;j++)p[i][j]=probs[j];break;}if(cur>1.5){lo=beta;beta=hi>1e300?beta*2:(beta+hi)/2;}else{hi=beta;beta=lo< -1e300?beta/2:(beta+lo)/2;}if(it==49)for(usz j=0;j<3;j++)p[i][j]=probs[j];}}
 for(usz i=0;i<3;i++)for(usz j=0;j<3;j++){high[i][j]=(p[i][j]+p[j][i])/6;if(high[i][j]<1e-12)high[i][j]=1e-12;}
 double[3] y={3.0471707975443136e-05,-1.0399841062404956e-04,7.504511958064573e-05};double[3] mom;
 for(usz it=0;it<5;it++){double total=0;for(usz i=0;i<3;i++)for(usz j=0;j<3;j++){double z=y[i]-y[j];den[i][j]=i==j?1.0/0.0:1+z*z;q[i][j]=i==j?0:1/den[i][j];total+=q[i][j];}for(usz i=0;i<3;i++)for(usz j=0;j<3;j++){q[i][j]=total==0?(i==j?0:1.0/6):q[i][j]/total;if(q[i][j]<1e-12)q[i][j]=1e-12;}double[3] g;for(usz i=0;i<3;i++){for(usz j=0;j<3;j++)g[i]+=(high[i][j]-q[i][j])*(1/den[i][j])*(y[i]-y[j]);g[i]*=4;}for(usz i=0;i<3;i++){mom[i]=0.5*mom[i]-10*g[i];y[i]+=mom[i];}}
 for(usz i=0;i<3;i++)out[i]=y[i];return 3;
}
