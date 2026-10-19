// PolyBench/C fdtd-2d bounded port. See benchmarks/f/fdtd_2d/LICENSE.txt.
module fdtd_2d;
extern fn double trunc(double value);
const long MAX_NX=6, MAX_NY=6, MAX_TMAX=4;
fn long fdtd_2d(double* input, usz length, double* output, usz capacity) @export("fdtd_2d") {
    if(input==null || length!=3) return -1;
    for(usz q=0;q<3;q++){double v=input[q];if(v!=v||trunc(v)!=v)return -1;}
    double tv=input[0], xv=input[1], yv=input[2];
    if(tv<0||tv>MAX_TMAX||xv<1||xv>MAX_NX||yv<1||yv>MAX_NY)return -1;
    usz tmax=(usz)tv,nx=(usz)xv,ny=(usz)yv,n=nx*ny,required=3*n;
    if(output==null||capacity<required)return -2;
    double ex[36]={0.0},ey[36]={0.0},hz[36]={0.0},fict[4]={0.0},staged[108]={0.0};
    for(usz t=0;t<tmax;t++)fict[t]=(double)t;
    for(usz i=0;i<nx;i++)for(usz j=0;j<ny;j++){ex[i*ny+j]=(double)(i*(j+1))/(double)nx;ey[i*ny+j]=(double)(i*(j+2))/(double)ny;hz[i*ny+j]=(double)(i*(j+3))/(double)nx;}
    for(usz t=0;t<tmax;t++){
        for(usz j=0;j<ny;j++)ey[j]=fict[t];
        for(usz i=1;i<nx;i++)for(usz j=0;j<ny;j++)ey[i*ny+j]=ey[i*ny+j]-0.5*(hz[i*ny+j]-hz[(i-1)*ny+j]);
        for(usz i=0;i<nx;i++)for(usz j=1;j<ny;j++)ex[i*ny+j]=ex[i*ny+j]-0.5*(hz[i*ny+j]-hz[i*ny+j-1]);
        for(usz i=0;i+1<nx;i++)for(usz j=0;j+1<ny;j++)hz[i*ny+j]=hz[i*ny+j]-0.7*((ex[i*ny+j+1]-ex[i*ny+j])+(ey[(i+1)*ny+j]-ey[i*ny+j]));
    }
    for(usz i=0;i<n;i++){staged[i]=ex[i];staged[n+i]=ey[i];staged[2*n+i]=hz[i];}
    for(usz i=0;i<required;i++)output[i]=staged[i];return (long)required;
}
