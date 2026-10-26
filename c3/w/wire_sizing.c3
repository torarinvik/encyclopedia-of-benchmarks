module wire_sizing;
extern fn double floor(double value);
const int N=6;const int F=7;const int MAX_INPUT=17;
fn double abs_f(double x){return x<0.0?-x:x;}
fn void put_i64(char* out,usz at,long value){ulong bits=(ulong)value;for(usz i=0;i<8;i++){out[at+i]=(char)(bits&255);bits>>=8;}}
fn long wire_sizing(long* values,usz length,char* output,usz capacity) @export("wire_sizing"){
 if(values==null||length<7||length>MAX_INPUT||values[0]<1||values[0]>N)return -1;int n=(int)values[0];long l=values[1],rd=values[2],cl=values[3],r0=values[4];if(l<1||l>1000||rd<1||rd>1000||cl<1||cl>1000||r0<1||r0>1000||length!=(usz)(5+2*n))return -1;
 long[N] h={};long[N] c={};for(int i=0;i<n;i++){h[i]=values[5+i];c[i]=values[5+n+i];if(h[i]<1||h[i]>32||c[i]<1||c[i]>1000||(i>0&&h[i]>=h[i-1])||(i>0&&c[i]>=c[i-1]))return -1;}
 double[N*N] phi={};double[N] rho={};for(int i=0;i<n;i++){rho[i]=(double)rd*(double)c[i]+(double)cl*(double)r0/(double)h[i];for(int j=0;j<n;j++){int lo=i<j?i:j,hi=i>j?i:j;phi[i*N+j]=(double)r0*(double)c[hi]/(double)h[lo];}}
 double best=1.0e300;double[N] best_l={};bool found=false;uint limit=(uint)1<<n;
 for(uint mask=1;mask<limit;mask++){int[N] ids={};int k=0;for(int i=0;i<n;i++)if((mask&((uint)1<<i))!=0){ids[k]=i;k++;}double[N+1][N+2] a={};for(int r=0;r<k;r++){for(int q=0;q<k;q++)a[r][q]=phi[ids[r]*N+ids[q]];a[r][k]=1.0;a[r][k+1]=-rho[ids[r]];}for(int q=0;q<k;q++)a[k][q]=1.0;a[k][k+1]=(double)l;
  bool ok=true;for(int col=0;col<=k;col++){int pivot=col;for(int r=col+1;r<=k;r++)if(abs_f(a[r][col])>abs_f(a[pivot][col]))pivot=r;if(abs_f(a[pivot][col])<1.0e-12){ok=false;break;}if(pivot!=col)for(int q=col;q<=k+1;q++){double t=a[col][q];a[col][q]=a[pivot][q];a[pivot][q]=t;}double div=a[col][col];for(int q=col;q<=k+1;q++)a[col][q]/=div;for(int r=0;r<=k;r++)if(r!=col){double f=a[r][col];for(int q=col;q<=k+1;q++)a[r][q]-=f*a[col][q];}}
  if(!ok)continue;double[N] x={};for(int r=0;r<k;r++)x[ids[r]]=a[r][k+1];double lambda=a[k][k+1],sum=0.0;for(int i=0;i<n;i++){if(x[i] < -1.0e-8)ok=false;sum+=x[i];double g=rho[i]+lambda;for(int j=0;j<n;j++)g+=phi[i*N+j]*x[j];if((mask&((uint)1<<i))==0&&g < -1.0e-7)ok=false;}if(abs_f(sum-(double)l)>1.0e-7)ok=false;if(!ok)continue;
  double objective=(double)(rd*cl);for(int i=0;i<n;i++){objective+=rho[i]*x[i];for(int j=0;j<n;j++)objective+=0.5*x[i]*phi[i*N+j]*x[j];}if(!found||objective<best-1.0e-7){found=true;best=objective;for(int i=0;i<n;i++)best_l[i]=x[i];}
 }
 if(!found)return -1;long[F] fields={};fields[0]=(long)floor(best*1000000.0+0.5);for(int i=0;i<n;i++){double q=best_l[i]<0.0?0.0:best_l[i];fields[i+1]=(long)floor(q*1000000.0+0.5);}usz bytes=8*(usz)(n+1);if(output==null||capacity<bytes)return -2;char[8*F] staged={};for(int i=0;i<n+1;i++)put_i64(staged,8*(usz)i,fields[i]);for(usz i=0;i<bytes;i++)output[i]=staged[i];return (long)bytes;
}
