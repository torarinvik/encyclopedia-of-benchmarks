module polybius;
fn long polybius(long* v,usz n,char* out,usz cap) @export("polybius") {
    if(v==null||n<1||n>65||v[0]<0||v[0]>64||n!=(usz)v[0]+1)return -1;
    usz count=(usz)v[0],needed=count*2;if(needed>cap||(needed>0&&out==null))return -2;
    for(usz i=0;i<count;i++){long x=v[i+1];if(x>=97&&x<=122)x-=32;if(x<65||x>90||x==74)return -1;long index=x-65;if(x>74)index-=1;out[i*2]=(char)(65+index/5);out[i*2+1]=(char)(65+index%5);}
    return (long)needed;
}
