module graphai_frontier_sampler;
import std::math;
fn long graphai_frontier_sampler(double* input,usz length,double* output,usz capacity) @export("graphai_frontier_sampler"){
    const usz N=8,M=24,R=4,MAX_INPUT=4+N+M+22*R;if(input==null||length<3||length>MAX_INPUT)return -1;
    for(usz q=0;q<length;q++)if(!math.is_finite(input[q]))return -1;double nv=input[0],mv=input[1],rv=input[2];
    if(nv!=(double)(long)nv||mv!=(double)(long)mv||rv!=(double)(long)rv||nv<1||nv>N||mv<0||mv>M||rv<1||rv>R)return -1;
    usz n=(usz)nv,m=(usz)mv,r=(usz)rv,required=22*r;if(length!=4+n+m+22*r)return -1;
    usz root_at=3,row_at=root_at+r,col_at=row_at+n+1,choice_at=col_at+m;usz rows[N+1]={0},cols[M]={0},front[R*12]={0},next[R*12]={0};double staged[R*22]={0.0};
    for(usz i=0;i<r;i++){double x=input[root_at+i];if(x!=(double)(long)x||x<0||x>=n)return -1;front[i]=(usz)x;staged[i]=x;}
    if(input[row_at]!=0||input[col_at-1]!=(double)m)return -1;
    for(usz i=0;i<=n;i++){double x=input[row_at+i];if(x!=(double)(long)x||x<0||x>m)return -1;rows[i]=(usz)x;if(i&&rows[i]<rows[i-1])return -1;}
    for(usz e=0;e<m;e++){double x=input[col_at+e];if(x!=(double)(long)x||x<0||x>=n)return -1;cols[e]=(usz)x;}
    if(output==null||capacity<required)return -2;
    usz fanouts[3]={3,2,2},front_size=r,choice=0,out_at=r;
    for(usz round=0;round<3;round++){usz next_size=front_size*fanouts[round];for(usz i=0;i<front_size;i++){usz parent=front[i],begin=rows[parent],degree=rows[parent+1]-begin;if(degree==0)return -1;
        for(usz j=0;j<fanouts[round];j++){double x=input[choice_at+choice];choice++;if(x!=(double)(long)x||x<0||x>=degree)return -1;usz v=cols[begin+(usz)x];next[i*fanouts[round]+j]=v;staged[out_at]=(double)v;out_at++;}}
        for(usz i=0;i<next_size;i++)front[i]=next[i];front_size=next_size;}
    if(choice!=21*r||out_at!=required)return -1;for(usz q=0;q<required;q++)output[q]=staged[q];return (long)required;
}
