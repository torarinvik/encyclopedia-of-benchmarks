module graphai_gcn_aggregation;
import std::math;
fn long graphai_gcn_aggregation(double* input, usz length, double* output, usz capacity)
    @export("graphai_gcn_aggregation") {
    const usz N=8,M=24,D=4,MAX_INPUT=4+3*N+M+N*D;
    if(input==null||length<7||length>MAX_INPUT)return -1;
    for(usz q=0;q<length;q++)if(!math.is_finite(input[q]))return -1;
    double nv=input[0],mv=input[1],dv=input[2];
    if(nv!=(double)(long)nv||mv!=(double)(long)mv||dv!=(double)(long)dv||nv<1||nv>N||mv<0||mv>M||dv<1||dv>D)return -1;
    usz n=(usz)nv,m=(usz)mv,d=(usz)dv;if(length!=4+3*n+m+n*d)return -1;
    usz oa=3,ea=oa+n+1,la=ea+m,ra=la+n,fa=ra+n;
    if(input[oa]!=0||input[ea-1]!=(double)m)return -1;
    usz rowptr[N+1]={0},colind[M]={0};
    for(usz i=0;i<=n;i++){double x=input[oa+i];if(x!=(double)(long)x||x<0||x>m)return -1;rowptr[i]=(usz)x;if(i>0&&rowptr[i]<rowptr[i-1])return -1;}
    for(usz e=0;e<m;e++){double x=input[ea+e];if(x!=(double)(long)x||x<0||x>=n)return -1;colind[e]=(usz)x;}
    for(usz i=0;i<n;i++)if(input[la+i]<-4||input[la+i]>4||input[ra+i]<-4||input[ra+i]>4)return -1;
    for(usz q=0;q<n*d;q++)if(input[fa+q]<-8||input[fa+q]>8)return -1;
    usz required=n*d;if(output==null||capacity<required)return -2;
    double staged[N*D]={0.0};
    for(usz src=0;src<n;src++)for(usz e=rowptr[src];e<rowptr[src+1];e++){usz dst=colind[e];double w=input[la+src]*input[ra+dst];for(usz k=0;k<d;k++)staged[src*d+k]+=w*input[fa+dst*d+k];}
    for(usz q=0;q<required;q++)output[q]=staged[q];return (long)required;
}
