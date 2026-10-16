module crc8_model;
const usz MAX_LENGTH=100001;
fn long reverse8(long value){long result=0;for(int i=0;i<8;i++){result=(result<<1)|(value&1);value=value>>1;}return result;}
fn long crc8_model(long* input,usz length) @export("crc8_model"){
 if(input==null||length<6)return -1;long poly=input[0],init=input[1],rin=input[2],rout=input[3],xo=input[4],count=input[5];
 if(poly<0||poly>255||init<0||init>255||xo<0||xo>255||(rin!=0&&rin!=1)||(rout!=0&&rout!=1)||count<0||count>(long)MAX_LENGTH||length!=6+(usz)count)return -1;
 long crc=init;for(usz i=0;i<(usz)count;i++){long value=input[6+i];if(value<0||value>255)return -1;long byte=value;if(rin==1)byte=reverse8(byte);crc=crc^byte;for(int bit=0;bit<8;bit++){long top=crc&128;crc=(crc<<1)&255;if(top!=0)crc=crc^poly;}}
 if(rout==1)crc=reverse8(crc);return crc^xo;
}
