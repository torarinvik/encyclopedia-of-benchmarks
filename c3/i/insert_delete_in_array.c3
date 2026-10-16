module insert_delete_in_array;
fn void put_i32(char* out, usz i, long x) { uint v=(uint)(int)x; out[4*i]=(char)v; out[4*i+1]=(char)(v>>8); out[4*i+2]=(char)(v>>16); out[4*i+3]=(char)(v>>24); }
fn long insert_delete_in_array(long* v,usz n,char* out,usz cap) @export("insert_delete_in_array") {
 if(v==null||n<4||n>260)return -1;long op=v[0],len=v[1],pos=v[2],element=v[3];if((op!=0&&op!=1)||len<0||len>256||n!=(usz)len+4||pos<0||(op==0?pos>len:pos>=len)||(op==1&&element!=0))return -1;for(usz i=0;i<(usz)len;i++)if(v[i+4]<-2147483648L||v[i+4]>2147483647L)return -1;if(op==0&&(element<-2147483648L||element>2147483647L))return -1;usz outn=(usz)len+(usz)(op==0);if(outn*4>cap||(outn>0&&out==null))return -2;for(usz i=0;i<outn;i++){long x;if(op==0)x=i<(usz)pos?v[i+4]:(i==(usz)pos?element:v[i+3]);else x=i<(usz)pos?v[i+4]:v[i+5];put_i32(out,i,x);}return (long)(outn*4);
}
