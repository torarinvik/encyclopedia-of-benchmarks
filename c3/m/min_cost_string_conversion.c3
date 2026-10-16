module min_cost_string_conversion;
const usz MAX_TEXT=32, MAX_CELLS=1089;
fn void put_i64_le(char* out, usz* pos, long value) { ulong bits=(ulong)value; for(usz b=0;b<8;b++) { out[*pos]=(char)(bits>>(8*b)); *pos+=1; } }
fn long min_cost_string_conversion(long* input, usz length, char* output, usz capacity) @export("min_cost_string_conversion") {
    if(input==null||length<6||length>70)return -1;
    long sn=input[0];if(sn<0||sn>32)return -1;usz src=(usz)sn,dpos=1+src;if(dpos>=length)return -1;
    long dn=input[dpos];if(dn<0||dn>32)return -1;usz dst=(usz)dn;if(length!=6+src+dst)return -1;usz target=dpos+1,cost=target+dst;
    for(usz i=0;i<src;i++)if(input[1+i]<0||input[1+i]>127)return -1;
    for(usz j=0;j<dst;j++)if(input[target+j]<0||input[target+j]>127)return -1;
    for(usz k=0;k<4;k++)if(input[cost+k]< -1000||input[cost+k]>1000)return -1;
    long cc=input[cost],rc=input[cost+1],dc=input[cost+2],ic=input[cost+3];usz rows=src+1,cols=dst+1,cells=rows*cols;
    long[MAX_CELLS] dp={},op={},ca={},cb={};
    for(usz j=1;j<cols;j++){usz x=j;dp[x]=dp[x-1]+ic;op[x]=4;cb[x]=input[target+j-1];}
    for(usz i=1;i<rows;i++){usz x=i*cols;dp[x]=dp[x-cols]+dc;op[x]=3;ca[x]=input[i];}
    for(usz i=1;i<rows;i++)for(usz j=1;j<cols;j++){
        usz x=i*cols+j,up=x-cols,left=x-1,diag=up-1;long a=input[i],b=input[target+j-1];
        long best=dp[diag]+(a==b?cc:rc),code=a==b?1:2,aa=a,bb=a==b?0:b;
        long deletion=dp[up]+dc;if(deletion<best){best=deletion;code=3;aa=a;bb=0;}
        long insertion=dp[left]+ic;if(insertion<best){best=insertion;code=4;aa=0;bb=b;}
        dp[x]=best;op[x]=code;ca[x]=aa;cb[x]=bb;
    }
    usz needed=32+cells*32;if(output==null||capacity<needed)return -2;usz p=0;
    put_i64_le(output,&p,(long)rows);put_i64_le(output,&p,(long)cols);for(usz x=0;x<cells;x++)put_i64_le(output,&p,dp[x]);
    put_i64_le(output,&p,(long)rows);put_i64_le(output,&p,(long)cols);for(usz x=0;x<cells;x++){put_i64_le(output,&p,op[x]);put_i64_le(output,&p,ca[x]);put_i64_le(output,&p,cb[x]);}
    return (long)p;
}
