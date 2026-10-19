// PolyBench/C seidel-2d bounded port. See benchmarks/s/polybench_seidel_2d/LICENSE.txt.
module polybench_seidel_2d;
extern fn double trunc(double value);
const long MAX_N=6;
fn long polybench_seidel_2d(double* input,usz length,double* output,usz capacity) @export("polybench_seidel_2d"){
    if(input==null||length!=2)return -1;double nv=input[0],sv=input[1];
    if(nv!=nv||sv!=sv||trunc(nv)!=nv||trunc(sv)!=sv||nv<1||nv>MAX_N||sv<0||sv>4)return -1;
    usz n=(usz)nv,steps=(usz)sv,cells=n*n;if(output==null||capacity<cells)return -2;
    double a[36]={0.0},staged[36]={0.0};
    for(usz i=0;i<n;i++)for(usz j=0;j<n;j++)a[i*n+j]=((double)i*(double)(j+2)+2.0)/(double)n;
    for(usz t=0;t<steps;t++)for(usz i=1;i+1<n;i++)for(usz j=1;j+1<n;j++){usz q=i*n+j;double sum=a[q-n-1]+a[q-n]+a[q-n+1]+a[q-1]+a[q]+a[q+1]+a[q+n-1]+a[q+n]+a[q+n+1];a[q]=sum/9.0;}
    for(usz q=0;q<cells;q++)staged[q]=a[q];for(usz q=0;q<cells;q++)output[q]=staged[q];return (long)cells;
}
