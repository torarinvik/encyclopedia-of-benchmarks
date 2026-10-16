module uniform_crossover;

fn void put_i64_le(char* output, usz offset, long value) { ulong bits=(ulong)value;for(usz byte=0;byte<8;byte++)output[offset+byte]=(char)((bits>>(8*byte))&255); }

fn long uniform_crossover(long* input,usz length,char* output,usz capacity) @export("uniform_crossover") {
    if(input==null||length<4||length>193)return -1;long n=input[0];if(n<1||n>64||length!=(usz)(1+3*n))return -1;
    for(usz i=0;i<(usz)n;i++)if(input[1+i]!=0&&input[1+i]!=1)return -1;
    for(usz i=0;i<(usz)(2*n);i++)if(input[1+(usz)n+i]<-2147483648||input[1+(usz)n+i]>2147483647)return -1;
    usz count=(usz)n,bytes=16*(usz)n;if(output==null||capacity<bytes)return -2;
    for(usz i=0;i<count;i++){long alpha=input[1+i],p=input[1+count+i],q=input[1+2*count+i];long c1=alpha!=0?p:q,c2=alpha!=0?q:p;put_i64_le(output,i*8,c1);put_i64_le(output,(count+i)*8,c2);}
    return (long)bytes;
}
