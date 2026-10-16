module operators;
void put_i32(char*out,usz off,long x){uint bits=(uint)(int)x;for(usz k=0;k<4;k++){out[off+k]=(char)(bits&255);bits>>=8;}}
fn long operators(long*v,usz n,char*out,usz cap)@export("operators"){
 if(v==null||n<5)return -1;long op=v[0],ra=v[1],ca=v[2];if((op!=0&&op!=1)||ra<1||ra>16||ca<0||ca>16||ra*ca>256)return -1;usz count=(usz)(ra*ca),pb=3+count;if(n<pb+2)return -1;long rb=v[pb],cb=v[pb+1];if(rb<1||rb>16||cb<0||cb>16||rb*cb>256||n!=pb+2+(usz)(rb*cb))return -1;for(usz i=0;i<count;i++)if(v[3+i]<-1000000||v[3+i]>1000000)return -1;for(usz i=0;i<(usz)(rb*cb);i++)if(v[pb+2+i]<-1000000||v[pb+2+i]>1000000)return -1;if(ra!=rb||ca!=cb)return -1;usz bytes=count*4;if(cap<bytes||(bytes>0&&out==null))return -2;for(usz i=0;i<count;i++){long a=v[3+i],b=v[pb+2+i];put_i32(out,i*4,op==0?a+b:a-b);}return (long)count;
}
