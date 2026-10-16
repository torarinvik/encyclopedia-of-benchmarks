module hill_encoder;
fn long hill_encoder(long *v,usz n,char *out,usz cap) @export("hill_encoder") {
 if(v==null||n<10||n>74||v[0]<0||v[0]>64||n!=10+(usz)v[0])return -1;
 usz len=(usz)v[0],padded=(len+2)/3*3;long[66] text;long[9] key;long[66] result;
 for(usz i=0;i<len;i++){if(v[1+i]<65||v[1+i]>90)return -1;text[i]=v[1+i];}
 for(usz i=len;i<padded;i++)text[i]=32;
 for(usz i=0;i<9;i++){key[i]=v[1+len+i];if(key[i]<-2||key[i]>2)return -1;}
 for(usz off=0;off<padded;off+=3){for(usz row=0;row<3;row++){long sum=0;for(usz col=0;col<3;col++)sum+=key[row*3+col]*text[off+col];if(sum<0||sum>65535)return -1;result[off+row]=sum;}}
 usz bytes=padded*8;if(out==null||cap<bytes)return -2;for(usz i=0;i<padded;i++){ulong b=@bitcast(ulong,result[i]);for(usz k=0;k<8;k++){out[i*8+k]=(char)(b&255);b>>=8;}}return (long)bytes;
}
