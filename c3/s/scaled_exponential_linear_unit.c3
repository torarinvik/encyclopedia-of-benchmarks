module scaled_exponential_linear_unit;
import std::math;

fn long scaled_exponential_linear_unit(long* v, usz n, char* output, usz cap) @export("scaled_exponential_linear_unit") {
 if(v==null||n<3||n>259||v[0]<0||v[0]>256||n!=(usz)v[0]+3||v[1]<-10000000||v[1]>10000000||v[2]<-10000000||v[2]>10000000)return -1;
 usz count=(usz)v[0],bytes=count*8;for(usz i=0;i<count;i++)if(v[i+3]<-20000000||v[i+3]>20000000)return -1;if(output==null||cap<bytes)return -2;f64 alpha=(f64)v[1]/1000000.0,lambda=(f64)v[2]/1000000.0;
 for(usz i=0;i<count;i++){f64 x=(f64)v[i+3]/1000000.0;f64 inner=x>0.0?x:alpha*(math::exp(x)-1.0);f64 y=lambda*inner;long q=(long)math::floor(y*1000000000.0+0.5);uint64 raw=(uint64)q;for(usz b=0;b<8;b++)output[i*8+b]=(char)(raw>>(8*b));}return (long)bytes;
}
