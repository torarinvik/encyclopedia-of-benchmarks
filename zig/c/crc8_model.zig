const MAX_LENGTH:usize=100_001;
fn reverse8(value_in:i64)i64{var value=value_in;var result:i64=0;for(0..8)|_|{result=(result<<1)|(value&1);value>>=1;}return result;}
export fn crc8_model(input:[*c]const i64,length:usize)i64{
 if(input==null or length<6)return -1;const poly=input[0];const initial=input[1];const rin=input[2];const rout=input[3];const xo=input[4];const count=input[5];
 if(poly<0 or poly>255 or initial<0 or initial>255 or xo<0 or xo>255 or (rin!=0 and rin!=1) or (rout!=0 and rout!=1) or count<0 or count>MAX_LENGTH or length!=6+@as(usize,@intCast(count)))return -1;
 var crc=initial;for(0..@as(usize,@intCast(count)))|i|{const value=input[6+i];if(value<0 or value>255)return -1;var byte=value;if(rin==1)byte=reverse8(byte);crc^=byte;for(0..8)|_|{const top=crc&128;crc=(crc<<1)&255;if(top!=0)crc^=poly;}}
 if(rout==1)crc=reverse8(crc);return crc^xo;
}
