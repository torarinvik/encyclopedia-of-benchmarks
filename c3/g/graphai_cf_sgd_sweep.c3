module graphai_cf_sgd_sweep;
import std::math;
fn long graphai_cf_sgd_sweep(double* input,usz length,double* output,usz capacity) @export("graphai_cf_sgd_sweep"){
    const usz N=8,M=24,K=4,MAX_INPUT=7+N+2*M+N*K;if(input==null||length<6||length>MAX_INPUT)return -1;
    for(usz q=0;q<length;q++)if(!math.is_finite(input[q]))return -1;double uv=input[0],iv=input[1],mv=input[2],kv=input[3];
    if(uv!=(double)(long)uv||iv!=(double)(long)iv||mv!=(double)(long)mv||kv!=(double)(long)kv||uv<1||uv>7||iv<1||iv>7||mv<0||mv>M||kv<1||kv>K)return -1;
    usz users=(usz)uv,items=(usz)iv,n=users+items,m=(usz)mv,k=(usz)kv;double lambda=input[4],step=input[5];if(n>N||lambda<0||lambda>1||step<0||step>0.01||length!=7+n+2*m+n*k)return -1;
    usz rp=6,ci=rp+n+1,ra=ci+m,la=ra+m;if(input[rp]!=0||input[ci-1]!=(double)m)return -1;usz rows[N+1]={0},cols[M]={0};
    for(usz i=0;i<=n;i++){double x=input[rp+i];if(x!=(double)(long)x||x<0||x>m)return -1;rows[i]=(usz)x;if(i&&rows[i]<rows[i-1])return -1;}
    for(usz u=users;u<n;u++)if(rows[u]!=rows[u+1])return -1;
    for(usz e=0;e<m;e++){double x=input[ci+e];if(x!=(double)(long)x||x<users||x>=n)return -1;cols[e]=(usz)x;}
    for(usz e=0;e<m;e++)if(input[ra+e]<-4||input[ra+e]>4)return -1;for(usz q=0;q<n*k;q++)if(input[la+q]<-2||input[la+q]>2)return -1;
    usz required=n*k;if(output==null||capacity<required)return -2;double error[N*K]={0.0},staged[N*K]={0.0};
    for(usz u=0;u<users;u++)for(usz e=rows[u];e<rows[u+1];e++){usz v=cols[e];double estimate=0;for(usz j=0;j<k;j++)estimate+=input[la+u*k+j]*input[la+v*k+j];double delta=input[ra+e]-estimate;for(usz j=0;j<k;j++)error[u*k+j]+=input[la+v*k+j]*delta;}
    for(usz v=0;v<n;v++)for(usz j=0;j<k;j++){usz q=v*k+j;staged[q]=input[la+q]+step*(-lambda*input[la+q]+error[q]);}
    for(usz q=0;q<required;q++)output[q]=staged[q];return (long)required;
}
