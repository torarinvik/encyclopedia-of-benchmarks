// Clean-room fixed-rational-scale geometric 2D pattern matching profile.
module two_dimensional_scaled_pattern_matching;
const usz MAX_INPUT=186;const usz MAX_FIELDS=289;
fn void put(char* out,usz at,long value){ulong bits=(ulong)value;for(usz b=0;b<8;++b){out[at+b]=(char)(bits&255ul);bits>>=8;}}
fn long two_dimensional_scaled_pattern_matching(long* v,usz n,char* out,usz cap) @export("two_dimensional_scaled_pattern_matching"){
 if(v==null||n<6||n>MAX_INPUT)return -1;long h0=v[0],w0=v[1],ph0=v[2],pw0=v[3],p=v[4],q=v[5];if(h0<1||h0>12||w0<1||w0>12||ph0<1||ph0>6||pw0<1||pw0>6||q<1||q>8||p<q||p>2*q)return -1;
 usz h=(usz)h0,w=(usz)w0,ph=(usz)ph0,pw=(usz)pw0;if(n!=6+h*w+ph*pw)return -1;for(usz i=0;i<h*w+ph*pw;++i){if(v[6+i]<0||v[6+i]>255)return -1;}
 long[MAX_FIELDS] fields={};usz count=1;for(usz r=0;r<h;++r){for(usz c=0;c<w;++c){if(p*ph0>q*(long)(h-r)||p*pw0>q*(long)(w-c))continue;bool matched=true;
  for(usz y=0;y<h-r;++y){if((2*(long)y+1)*q>=2*p*ph0)continue;usz py=(usz)(((2*(long)y+1)*q)/(2*p));for(usz x=0;x<w-c;++x){if((2*(long)x+1)*q>=2*p*pw0)continue;usz px=(usz)(((2*(long)x+1)*q)/(2*p));if(v[6+(r+y)*w+c+x]!=v[6+h*w+py*pw+px]){matched=false;break;}}if(!matched)break;}
  if(matched){fields[count]=(long)r;fields[count+1]=(long)c;count+=2;}
 }}fields[0]=(long)((count-1)/2);usz bytes=8*count;if(out==null||cap<bytes)return -2;for(usz i=0;i<count;++i)put(out,8*i,fields[i]);return (long)bytes;
}
