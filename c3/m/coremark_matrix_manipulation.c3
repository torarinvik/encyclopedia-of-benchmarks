module coremark_matrix_manipulation;

fn ushort crc_byte(uint8 value, ushort crc0) {
    ushort crc=crc0;
    for (usz i=0;i<8;i++) { ushort mix=(ushort)(value&1)^(crc&1); value>>=1; if(mix!=0)crc^=0x4002; crc>>=1; if(mix!=0)crc|=0x8000; else crc&=0x7fff; }
    return crc;
}
fn ushort crc16(short value,ushort crc) { ushort bits=(ushort)value; return crc_byte((uint8)(bits>>8),crc_byte((uint8)bits,crc)); }
fn short matrix_sum(long* c,short clip) { long tmp=0,prev=0,cur=0;short ret=0;for(usz i=0;i<9;i++){cur=c[i];tmp+=cur;if(tmp>clip){ret=(short)(ret+10);tmp=0;}else if(cur>prev)ret++;prev=cur;}return ret; }
fn void put_i64(char* out,usz offset,long value){ulong bits=(ulong)value;for(usz b=0;b<8;b++)out[offset+b]=(char)(bits>>(8*b));}

fn long coremark_matrix_manipulation(long* input,usz length,char* output,usz capacity) @export("coremark_matrix_manipulation") {
    if(input==null||length!=19)return -1;long raw=input[0];if(raw<0||raw>15)return -1;
    short[9] a;short[9] b;
    for(usz i=0;i<9;i++){if(input[1+i]<0||input[1+i]>127||input[10+i]<0||input[10+i]>127)return -1;a[i]=(short)input[1+i];b[i]=(short)input[10+i];}
    if(output==null||capacity<112)return -2;
    short value=(short)raw;short clip=(short)(value-4096);long[9] c;short[4] sums;
    for(usz i=0;i<9;i++)a[i]=(short)(a[i]+value);
    for(usz i=0;i<9;i++)c[i]=(long)a[i]*value;
    sums[0]=matrix_sum(&c[0],clip);
    for(usz i=0;i<3;i++){c[i]=0;for(usz j=0;j<3;j++)c[i]+=(long)a[i*3+j]*b[j];}
    sums[1]=matrix_sum(&c[0],clip);
    for(usz i=0;i<3;i++)for(usz j=0;j<3;j++){c[i*3+j]=0;for(usz k=0;k<3;k++)c[i*3+j]+=(long)a[i*3+k]*b[k*3+j];}
    sums[2]=matrix_sum(&c[0],clip);
    for(usz i=0;i<3;i++)for(usz j=0;j<3;j++){c[i*3+j]=0;for(usz k=0;k<3;k++){long t=(long)a[i*3+k]*b[k*3+j];c[i*3+j]+=((t>>2)&0xf)*((t>>5)&0x7f);}}
    sums[3]=matrix_sum(&c[0],clip);
    ushort crc=0;for(usz i=0;i<4;i++)crc=crc16(sums[i],crc);
    for(usz i=0;i<9;i++)a[i]=(short)(a[i]-value);
    long[14] result={};result[0]=(long)crc;for(usz i=0;i<4;i++)result[i+1]=sums[i];for(usz i=0;i<9;i++)result[i+5]=a[i];
    for(usz i=0;i<14;i++)put_i64(output,i*8,result[i]);return 112;
}
