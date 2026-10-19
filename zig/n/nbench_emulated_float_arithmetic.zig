const MAX_OPS:usize=8;
const MAX_INPUT:usize=1+13*MAX_OPS;
const IFPF=struct{typ:u8,sign:u8,exp:i16,mant:u64};
fn stickyRight(v:*IFPF,n:u32)void{for(0..n)|_|{const lost=v.mant&1;v.mant>>=1;if(lost!=0)v.mant|=1;}}
fn roundResult(v:*IFPF)void{if(v.typ==2)v.mant&=~@as(u64,7);}
fn normalize(v:*IFPF)void{while(v.mant>>63==0){v.mant<<=1;v.exp-=1;}}
fn addSub(x0:IFPF,y0:IFPF,op:u8)IFPF{
 var x=x0;var y=y0;var z=IFPF{.typ=2,.sign=x.sign,.exp=x.exp,.mant=0};const d:i32=@as(i32,x.exp)-@as(i32,y.exp);
 if(d>0)stickyRight(&y,@intCast(d)) else if(d<0){stickyRight(&x,@intCast(-d));z.sign=y.sign^op;z.exp=y.exp;}
 if((x.sign^y.sign^op)!=0){z.mant=x.mant -% y.mant;if(x.mant<y.mant){z.sign=y.sign^op;z.mant=y.mant -% x.mant;}if(z.mant==0){z.typ=0;z.sign=0;z.exp=-32767;}else normalize(&z);}
 else{z.mant=x.mant +% y.mant;if(z.mant<x.mant){z.exp+=1;z.mant=(z.mant>>1)|0x8000000000000000;}}
 roundResult(&z);return z;
}
fn multiply(x:IFPF,y:IFPF)IFPF{
 var z=IFPF{.typ=2,.sign=x.sign^y.sign,.exp=x.exp+y.exp,.mant=0};var high:u64=0;var low:u64=0;var mult=y.mant;
 for(0..64)|_|{var carry:u64=0;if(mult&1!=0){const old=high;high+%=x.mant;if(high<old)carry=1;}mult>>=1;const outgoing=high&1;high=(high>>1)|(carry<<63);low=(low>>1)|(outgoing<<63);}
 while(high>>63==0){const carry=low>>63;low<<=1;high=(high<<1)|carry;z.exp-=1;}if(low==0)high|=1;z.mant=high;roundResult(&z);return z;
}
fn divideEmulated(x:IFPF,y:IFPF)IFPF{
 var z=IFPF{.typ=2,.sign=x.sign^y.sign,.exp=x.exp-y.exp+128,.mant=0};var dividend=x.mant;var rem:u64=0;
 while(z.mant>>63==0){const carry=dividend>>63;dividend<<=1;const overflow=rem>>63;rem=(rem<<1)|carry;var bit:u64=0;if(overflow!=0 or rem>=y.mant){rem-%=y.mant;bit=1;}z.mant=(z.mant<<1)|bit;z.exp-=1;}roundResult(&z);return z;
}
export fn nbench_emulated_float_arithmetic(input:[*c]const i64,length:usize,output:[*c]u8,capacity:usize)i64{
 if(input==null or length<14 or length>MAX_INPUT+1)return -1;const raw=input[0];if(raw<1 or raw>MAX_OPS or length!=1+13*@as(usize,@intCast(raw)))return -1;const n:usize=@intCast(raw);var results=[_]IFPF{.{.typ=0,.sign=0,.exp=0,.mant=0}}**MAX_OPS;
 for(0..n)|i|{const p=1+13*i;const op=input[p];const sx=input[p+1];const ex=input[p+2];const sy=input[p+7];const ey=input[p+8];if(op<0 or op>3 or sx<0 or sx>1 or sy<0 or sy>1 or ex< -8 or ex>8 or ey< -8 or ey>8)return -1;var mx:u64=0;var my:u64=0;
  for(0..4)|j|{const a=input[p+3+j];const b=input[p+9+j];if(a<0 or a>65535 or b<0 or b>65535)return -1;mx=(mx<<16)|@as(u64,@intCast(a));my=(my<<16)|@as(u64,@intCast(b));}if(mx>>63==0 or my>>63==0)return -1;
  const x=IFPF{.typ=2,.sign=@intCast(sx),.exp=@intCast(ex),.mant=mx};const y=IFPF{.typ=2,.sign=@intCast(sy),.exp=@intCast(ey),.mant=my};
  results[i]=switch(op){0=>addSub(x,y,0),1=>addSub(x,y,1),2=>multiply(x,y),else=>divideEmulated(x,y)};const r=results[i];if(r.typ==2 and (r.exp< -32 or r.exp>32 or r.mant>>63==0))return -1;
 }
 const bytes=n*12;if(output==null or capacity<bytes)return -2;for(0..n)|i|{const v=results[i];const p=12*i;output[p]=v.typ;output[p+1]=v.sign;const e:u16=@bitCast(v.exp);output[p+2]=@truncate(e);output[p+3]=@truncate(e>>8);for(0..4)|j|{const w:u16=@truncate(v.mant>>(48-16*j));output[p+4+2*j]=@truncate(w);output[p+5+2*j]=@truncate(w>>8);}}return @intCast(bytes);
}
