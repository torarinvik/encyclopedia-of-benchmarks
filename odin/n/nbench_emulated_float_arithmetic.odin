package nbench_emulated_float_arithmetic

MAX_OPS :: 8
MAX_INPUT :: 1 + 13*MAX_OPS
IFPF :: struct { typ:u8, sign:u8, exp:i16, mant:u64 }

sticky_right :: proc(v:^IFPF,n:u32){for _ in 0..<n{lost:=v.mant&1;v.mant>>=1;if lost!=0{v.mant|=1}}}
round_result :: proc(v:^IFPF){if v.typ==2{v.mant&=0xfffffffffffffff8}}
normalize :: proc(v:^IFPF){for v.mant>>63==0{v.mant<<=1;v.exp-=1}}
add_sub :: proc(x0,y0:IFPF,op:u8)->IFPF{
 x,y:=x0,y0;z:=IFPF{2,x.sign,x.exp,0};d:=i32(x.exp)-i32(y.exp)
 if d>0{sticky_right(&y,u32(d))}else if d<0{sticky_right(&x,u32(-d));z.sign=y.sign^op;z.exp=y.exp}
 if x.sign^y.sign^op!=0{if x.mant<y.mant{z.sign=y.sign^op;z.mant=y.mant-x.mant}else{z.mant=x.mant-y.mant};if z.mant==0{z.typ=0;z.sign=0}else{normalize(&z)}}
 else{max:=u64(0xffffffffffffffff);if x.mant>max-y.mant{z.mant=x.mant-(max-y.mant)-1;z.exp+=1;z.mant=(z.mant>>1)|0x8000000000000000}else{z.mant=x.mant+y.mant}}
 round_result(&z);return z
}
multiply :: proc(x,y:IFPF)->IFPF{
 z:=IFPF{2,x.sign^y.sign,x.exp+y.exp,0};high,low,mult:=u64(0),u64(0),y.mant
 for _ in 0..<64{carry:=u64(0);if mult&1!=0{max:=u64(0xffffffffffffffff);if high>max-x.mant{carry=1;high=high-(max-x.mant)-1}else{high+=x.mant}};mult>>=1;outgoing:=high&1;high=(high>>1)|(carry<<63);low=(low>>1)|(outgoing<<63)}
 for high>>63==0{carry:=low>>63;low<<=1;high=(high<<1)|carry;z.exp-=1}
 if low==0{high|=1};z.mant=high;round_result(&z);return z
}
divide_emulated :: proc(x,y:IFPF)->IFPF{
 z:=IFPF{2,x.sign^y.sign,x.exp-y.exp+128,0};dividend,rem:=x.mant,u64(0)
 for z.mant>>63==0{carry:=dividend>>63;dividend<<=1;overflow:=rem>>63;rem=(rem<<1)|carry;bit:=u64(0);if overflow!=0{rem=rem+(u64(0xffffffffffffffff)-y.mant)+1;bit=1}else if rem>=y.mant{rem-=y.mant;bit=1};z.mant=(z.mant<<1)|bit;z.exp-=1}
 round_result(&z);return z
}

@(export)
nbench_emulated_float_arithmetic :: proc "c" (input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64{
 if input==nil||length<14||length>MAX_INPUT+1{return -1};raw:=input[0];if raw<1||raw>MAX_OPS||length!=c.size_t(1+13*raw){return -1};n:=int(raw);results:[MAX_OPS]IFPF={}
 for i in 0..<n{p:=1+13*i;op,sx,ex,sy,ey:=input[p],input[p+1],input[p+2],input[p+7],input[p+8];if op<0||op>3||sx<0||sx>1||sy<0||sy>1||ex< -8||ex>8||ey< -8||ey>8{return -1};mx,my:=u64(0),u64(0)
  for j in 0..<4{a,b:=input[p+3+j],input[p+9+j];if a<0||a>65535||b<0||b>65535{return -1};mx=(mx<<16)|u64(a);my=(my<<16)|u64(b)};if mx>>63==0||my>>63==0{return -1}
  x,y:=IFPF{2,u8(sx),i16(ex),mx},IFPF{2,u8(sy),i16(ey),my}
  if op==0{results[i]=add_sub(x,y,0)}else if op==1{results[i]=add_sub(x,y,1)}else if op==2{results[i]=multiply(x,y)}else{results[i]=divide_emulated(x,y)}
  r:=results[i];if r.typ==2&&(r.exp< -80||r.exp>32||r.mant>>63==0){return -1}
 }
 bytes:=n*12;if output==nil||capacity<c.size_t(bytes){return -2};for i in 0..<n{v:=results[i];p:=12*i;output[p]=v.typ;output[p+1]=v.sign;e:=u16(v.exp);output[p+2]=u8(e);output[p+3]=u8(e>>8);for j in 0..<4{w:=u16(v.mant>>(48-16*j));output[p+4+2*j]=u8(w);output[p+5+2*j]=u8(w>>8)}};return i64(bytes)
}
