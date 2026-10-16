module prefix_conversions_string;
fn usz append_i64(char* out,usz at,long value){if(value<0){out[at++]='-';value=-value;}if(value==0){out[at++]='0';return at;}char[24] rev;usz n=0;while(value>0){rev[n++]=(char)('0'+value%10);value/=10;}while(n>0)out[at++]=rev[--n];return at;}
fn long raw(char* out,long value){return (long)append_i64(out,0,value);}
fn long scaled(char* out,long value,long scale,char* name,usz name_len){if(value%scale!=0)return -1;usz at=append_i64(out,0,value/scale);out[at++]='.';out[at++]='0';out[at++]=' ';for(usz i=0;i<name_len;i++)out[at++]=name[i];return (long)at;}
fn long prefix_conversions_string(long* v,usz n,char* out,usz cap) @export("prefix_conversions_string"){
 if(v==null||n!=2||(v[0]!=0&&v[0]!=1)||v[1]< -1000000000000||v[1]>1000000000000)return -1;if(out==null||cap<8192)return -2;long x=v[1];if(x<=0)return raw(out,x);
 if(v[0]==0){if(x>1000000000)return scaled(out,x,1000000000,"giga",4);if(x>1000000)return scaled(out,x,1000000,"mega",4);if(x>1000)return scaled(out,x,1000,"kilo",4);if(x>100)return scaled(out,x,100,"hecto",5);if(x>10)return scaled(out,x,10,"deca",4);}
 else{if(x>1073741824)return scaled(out,x,1073741824,"giga",4);if(x>1048576)return scaled(out,x,1048576,"mega",4);if(x>1024)return scaled(out,x,1024,"kilo",4);}
 return raw(out,x);
}
