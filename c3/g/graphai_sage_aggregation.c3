module graphai_sage_aggregation;
import std::math;
fn long graphai_sage_aggregation(double* input,usz length,double* output,usz capacity) @export("graphai_sage_aggregation"){
    const usz N=8,M=24,D=4,MAX_INPUT=4+N+M+N*D;if(input==null||length<4||length>MAX_INPUT)return -1;
    for(usz q=0;q<length;q++)if(!math.is_finite(input[q]))return -1;double nv=input[0],mv=input[1],dv=input[2];
    if(nv!=(double)(long)nv||mv!=(double)(long)mv||dv!=(double)(long)dv||nv<1||nv>N||mv<0||mv>M||dv<1||dv>D)return -1;
    usz n=(usz)nv,m=(usz)mv,d=(usz)dv;if(length!=4+n+m+n*d)return -1;usz rp=3,ci=rp+n+1,xf=ci+m;
    if(input[rp]!=0||input[ci-1]!=(double)m)return -1;usz rows[N+1]={0},cols[M]={0};
    for(usz i=0;i<=n;i++){double x=input[rp+i];if(x!=(double)(long)x||x<0||x>m)return -1;rows[i]=(usz)x;if(i>0&&rows[i]<rows[i-1])return -1;}
    for(usz e=0;e<m;e++){double x=input[ci+e];if(x!=(double)(long)x||x<0||x>=n)return -1;cols[e]=(usz)x;}
    for(usz q=0;q<n*d;q++)if(input[xf+q]<-8||input[xf+q]>8)return -1;usz required=n*d;if(output==null||capacity<required)return -2;
    double staged[N*D]={0.0};for(usz src=0;src<n;src++){usz degree=rows[src+1]-rows[src];if(degree>0){double scale=1.0/(double)degree;for(usz e=rows[src];e<rows[src+1];e++){usz dst=cols[e];for(usz k=0;k<d;k++)staged[src*d+k]+=scale*input[xf+dst*d+k];}}}
    for(usz q=0;q<required;q++)output[q]=staged[q];return (long)required;
}
