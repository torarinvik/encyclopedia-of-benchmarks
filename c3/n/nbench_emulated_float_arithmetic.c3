module nbench_emulated_float_arithmetic;
const usz MAX_OPS=8;
const usz MAX_INPUT=105;
struct IFPF { uint8 type; uint8 sign; short exp; ulong mant; }
fn void sticky_right(IFPF* v,uint n){for(uint i=0;i<n;i+=1){ulong lost=v.mant&1;v.mant>>=1;if(lost!=0)v.mant|=1;}}
fn void round_result(IFPF* v){if(v.type==2)v.mant&=0xfffffffffffffff8;}
fn void normalize(IFPF* v){while((v.mant>>63)==0){v.mant<<=1;v.exp-=1;}}
fn IFPF add_sub(IFPF x,IFPF y,uint8 op){
 IFPF z={2,x.sign,x.exp,0};int d=(int)x.exp-(int)y.exp;
 if(d>0)sticky_right(&y,(uint)d);else if(d<0){sticky_right(&x,(uint)-d);z.sign=y.sign^op;z.exp=y.exp;}
 if((x.sign^y.sign^op)!=0){z.mant=x.mant-y.mant;if(x.mant<y.mant){z.sign=y.sign^op;z.mant=y.mant-x.mant;}if(z.mant==0){z.type=0;z.sign=0;z.exp=-32767;}else normalize(&z);}
 else{z.mant=x.mant+y.mant;if(z.mant<x.mant){z.exp+=1;z.mant=(z.mant>>1)|0x8000000000000000;}}
 round_result(&z);return z;
}
fn IFPF multiply(IFPF x,IFPF y){
 IFPF z={2,(uint8)(x.sign^y.sign),(short)(x.exp+y.exp),0};ulong high=0,low=0,mult=y.mant;
 for(uint i=0;i<64;i+=1){ulong carry=0;if(mult&1){ulong old=high;high+=x.mant;if(high<old)carry=1;}mult>>=1;ulong outgoing=high&1;high=(high>>1)|(carry<<63);low=(low>>1)|(outgoing<<63);}
 while((high>>63)==0){ulong carry=low>>63;low<<=1;high=(high<<1)|carry;z.exp-=1;}if(low==0)high|=1;z.mant=high;round_result(&z);return z;
}
fn IFPF divide_emulated(IFPF x,IFPF y){
 IFPF z={2,(uint8)(x.sign^y.sign),(short)(x.exp-y.exp+128),0};ulong dividend=x.mant,rem=0;
 while((z.mant>>63)==0){ulong carry=dividend>>63;dividend<<=1;ulong overflow=rem>>63;rem=(rem<<1)|carry;ulong bit=0;if(overflow!=0||rem>=y.mant){rem-=y.mant;bit=1;}z.mant=(z.mant<<1)|bit;z.exp-=1;}round_result(&z);return z;
}
fn long nbench_emulated_float_arithmetic(long* input,usz length,char* output,usz capacity) @export("nbench_emulated_float_arithmetic"){
 if(input==null||length<14||length>MAX_INPUT+1)return -1;long raw=input[0];if(raw<1||raw>8||length!=1+(usz)(13*raw))return -1;usz n=(usz)raw;IFPF[8] results;
 for(usz i=0;i<n;i+=1){usz p=1+13*i;long op=input[p],sx=input[p+1],ex=input[p+2],sy=input[p+7],ey=input[p+8];if(op<0||op>3||sx<0||sx>1||sy<0||sy>1||ex< -8||ex>8||ey< -8||ey>8)return -1;ulong mx=0,my=0;
  for(usz j=0;j<4;j+=1){long a=input[p+3+j],b=input[p+9+j];if(a<0||a>65535||b<0||b>65535)return -1;mx=(mx<<16)|(ulong)a;my=(my<<16)|(ulong)b;}if((mx>>63)==0||(my>>63)==0)return -1;IFPF x={2,(uint8)sx,(short)ex,mx},y={2,(uint8)sy,(short)ey,my};
  if(op==0)results[i]=add_sub(x,y,0);else if(op==1)results[i]=add_sub(x,y,1);else if(op==2)results[i]=multiply(x,y);else results[i]=divide_emulated(x,y);IFPF r=results[i];if(r.type==2&&(r.exp< -32||r.exp>32||(r.mant>>63)==0))return -1;
 }
 usz bytes=n*12;if(output==null||capacity<bytes)return -2;for(usz i=0;i<n;i+=1){IFPF v=results[i];usz p=i*12;output[p]=(char)v.type;output[p+1]=(char)v.sign;uint16 e=(uint16)v.exp;output[p+2]=(char)e;output[p+3]=(char)(e>>8);for(usz j=0;j<4;j+=1){uint16 w=(uint16)(v.mant>>(48-16*j));output[p+4+2*j]=(char)w;output[p+5+2*j]=(char)(w>>8);}}return (long)bytes;
}
