// PolyBench/C correlation bounded port. See benchmarks/c/polybench_correlation/LICENSE.txt.
module polybench_correlation;
extern fn double trunc(double value);
extern fn double sqrt(double value);
const long MAX_N=6,MAX_M=6;
fn long polybench_correlation(double* input,usz length,double* output,usz capacity) @export("polybench_correlation"){
    if(input==null||length!=2)return -1;double nv=input[0],mv=input[1];
    if(nv!=nv||mv!=mv||trunc(nv)!=nv||trunc(mv)!=mv||nv<1||nv>MAX_N||mv<1||mv>MAX_M)return -1;
    usz n=(usz)nv,m=(usz)mv,required=m*m;if(output==null||capacity<required)return -2;
    double data[36]={0.0},corr[36]={0.0},mean[6]={0.0},stddev[6]={0.0},staged[36]={0.0},float_n=(double)n;
    for(usz i=0;i<n;i++)for(usz j=0;j<m;j++)data[i*m+j]=(double)(i*j)/(double)m+(double)i;
    for(usz j=0;j<m;j++){mean[j]=0.0;for(usz i=0;i<n;i++)mean[j]+=data[i*m+j];mean[j]/=float_n;}
    for(usz j=0;j<m;j++){stddev[j]=0.0;for(usz i=0;i<n;i++){double d=data[i*m+j]-mean[j];stddev[j]+=d*d;}stddev[j]/=float_n;stddev[j]=sqrt(stddev[j]);stddev[j]=stddev[j]<=0.1?1.0:stddev[j];}
    double scale=sqrt(float_n);for(usz i=0;i<n;i++)for(usz j=0;j<m;j++){data[i*m+j]-=mean[j];data[i*m+j]/=scale*stddev[j];}
    for(usz i=0;i+1<m;i++){corr[i*m+i]=1.0;for(usz j=i+1;j<m;j++){corr[i*m+j]=0.0;for(usz k=0;k<n;k++)corr[i*m+j]+=data[k*m+i]*data[k*m+j];corr[j*m+i]=corr[i*m+j];}}
    corr[(m-1)*m+m-1]=1.0;for(usz q=0;q<required;q++)staged[q]=corr[q];for(usz q=0;q<required;q++)output[q]=staged[q];return (long)required;
}
