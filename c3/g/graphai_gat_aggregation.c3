module graphai_gat_aggregation;
import std::math;
fn long graphai_gat_aggregation(double* input,usz length,double* output,usz capacity) @export("graphai_gat_aggregation"){
    const usz N=8,M=24,D=4,MAX_INPUT=4+N+M+2*D+N*D;if(input==null||length<3||length>MAX_INPUT)return -1;
    for(usz q=0;q<length;q++)if(!math.is_finite(input[q]))return -1;double nv=input[0],mv=input[1],dv=input[2];
    if(nv!=(double)(long)nv||mv!=(double)(long)mv||dv!=(double)(long)dv||nv<1||nv>N||mv<0||mv>M||dv<1||dv>D)return -1;
    usz n=(usz)nv,m=(usz)mv,d=(usz)dv;if(length!=4+n+m+2*d+n*d)return -1;usz rp=3,ci=rp+n+1,al=ci+m,ar=al+d,xf=ar+d;
    if(input[rp]!=0||input[ci-1]!=(double)m)return -1;usz rows[N+1]={0},cols[M]={0};
    for(usz i=0;i<=n;i++){double x=input[rp+i];if(x!=(double)(long)x||x<0||x>m)return -1;rows[i]=(usz)x;if(i&&rows[i]<rows[i-1])return -1;}
    for(usz e=0;e<m;e++){double x=input[ci+e];if(x!=(double)(long)x||x<0||x>=n)return -1;cols[e]=(usz)x;}
    for(usz q=al;q<length;q++)if(input[q]<-8||input[q]>8)return -1;usz required=n*d;if(output==null||capacity<required)return -2;
    double staged[N*D]={0.0},scores[M]={0.0},weights[M]={0.0};
    for(usz src=0;src<n;src++){usz begin=rows[src],end=rows[src+1];if(begin==end)continue;double maximum=-1.0e300;
        for(usz e=begin;e<end;e++){usz dst=cols[e];double score=0;for(usz k=0;k<d;k++)score+=input[al+k]*input[xf+src*d+k];for(usz k=0;k<d;k++)score+=input[ar+k]*input[xf+dst*d+k];scores[e]=score>0?score:0.2*score;if(scores[e]>maximum)maximum=scores[e];}
        double total=0;for(usz e=begin;e<end;e++){weights[e]=math.exp(scores[e]-maximum);total+=weights[e];}
        for(usz e=begin;e<end;e++){usz dst=cols[e];double scale=weights[e]/total;for(usz k=0;k<d;k++)staged[src*d+k]+=scale*input[xf+dst*d+k];}
    }
    for(usz q=0;q<required;q++)output[q]=staged[q];return (long)required;
}
