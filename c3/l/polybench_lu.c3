// PolyBench/C lu bounded port. See benchmarks/l/polybench_lu/LICENSE.txt.
module polybench_lu;
extern fn double trunc(double value);
const long MAX_N=6;
fn long polybench_lu(double* input,usz length,double* output,usz capacity) @export("polybench_lu"){
    if(input==null||length!=1)return -1;double nv=input[0];
    if(nv!=nv||trunc(nv)!=nv||nv<1||nv>MAX_N)return -1;
    usz n=(usz)nv,cells=n*n;if(output==null||capacity<cells)return -2;
    double a[36]={0.0},base[36]={0.0},staged[36]={0.0};
    for(usz i=0;i<n;i++){for(usz j=0;j<=i;j++)base[i*n+j]=1.0-(double)j/(double)n;base[i*n+i]=1.0;}
    for(usz t=0;t<n;t++)for(usz r=0;r<n;r++)for(usz s=0;s<n;s++)a[r*n+s]+=base[r*n+t]*base[s*n+t];
    for(usz i=0;i<n;i++){
        for(usz j=0;j<i;j++){for(usz k=0;k<j;k++)a[i*n+j]-=a[i*n+k]*a[k*n+j];a[i*n+j]/=a[j*n+j];}
        for(usz j=i;j<n;j++)for(usz k=0;k<i;k++)a[i*n+j]-=a[i*n+k]*a[k*n+j];
    }
    for(usz q=0;q<cells;q++)staged[q]=a[q];for(usz q=0;q<cells;q++)output[q]=staged[q];return (long)cells;
}
