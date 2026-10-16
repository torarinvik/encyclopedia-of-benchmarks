package crc8_model
import "core:c"
MAX_LENGTH :: 100_001
reverse8 :: proc "contextless" (value_in:i64)->i64{value:=value_in;result:=i64(0);for i:=0;i<8;i+=1{result=(result<<1)|(value&1);value=value>>1};return result}
@(export)
crc8_model :: proc "c" (input:[^]i64,length:c.size_t)->i64{
 if input==nil||length<6 do return -1
 poly,init,rin,rout,xo,count:=input[0],input[1],input[2],input[3],input[4],input[5]
 if poly<0||poly>255||init<0||init>255||xo<0||xo>255||(rin!=0&&rin!=1)||(rout!=0&&rout!=1)||count<0||count>MAX_LENGTH||int(length)!=6+int(count) do return -1
 crc:=init
 for i:=0;i<int(count);i+=1{value:=input[6+i];if value<0||value>255 do return -1;byte:=value;if rin==1 do byte=reverse8(byte);crc=crc^byte;for bit:=0;bit<8;bit+=1{top:=crc&128;crc=(crc<<1)&255;if top!=0 do crc=crc^poly}}
 if rout==1 do crc=reverse8(crc);return crc^xo
}
