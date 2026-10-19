// PolyBench/C heat-3d bounded port. See benchmarks/h/heat_3d/LICENSE.txt.
module heat_3d;
extern fn double trunc(double value);
const long MAX_N=6;
fn long polybench_heat_3d(double* input,usz length,double* output,usz capacity) @export("polybench_heat_3d") {
    if(input==null||length!=2)return -1;
    double nv=input[0],sv=input[1];
    if(nv!=nv||sv!=sv||trunc(nv)!=nv||trunc(sv)!=sv||nv<1||nv>MAX_N||sv<0||sv>4)return -1;
    usz n=(usz)nv,steps=(usz)sv,cells=n*n*n;
    if(output==null||capacity<cells)return -2;
    double a[216]={0.0},b[216]={0.0},staged[216]={0.0};
    for(usz i=0;i<n;i++)for(usz j=0;j<n;j++)for(usz k=0;k<n;k++){usz q=i*n*n+j*n+k;a[q]=b[q]=(double)(i+j+(n-k))*10.0/(double)n;}
    for(usz t=0;t<steps;t++){
        for(usz i=1;i+1<n;i++)for(usz j=1;j+1<n;j++)for(usz k=1;k+1<n;k++){usz q=i*n*n+j*n+k;double c=a[q];b[q]=0.125*(a[q+n*n]-2.0*c+a[q-n*n])+0.125*(a[q+n]-2.0*c+a[q-n])+0.125*(a[q+1]-2.0*c+a[q-1])+c;}
        for(usz i=1;i+1<n;i++)for(usz j=1;j+1<n;j++)for(usz k=1;k+1<n;k++){usz q=i*n*n+j*n+k;double c=b[q];a[q]=0.125*(b[q+n*n]-2.0*c+b[q-n*n])+0.125*(b[q+n]-2.0*c+b[q-n])+0.125*(b[q+1]-2.0*c+b[q-1])+c;}
    }
    for(usz q=0;q<cells;q++)staged[q]=a[q];for(usz q=0;q<cells;q++)output[q]=staged[q];return (long)cells;
}
