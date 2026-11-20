module one_dimensional;
fn long one_dimensional(long*v,usz n,char*out,usz cap) @export("one_dimensional") {
 if(v==null||n!=1||v[0]<0||v[0]>11111111)return -1;char[8] digits;char[8] rules=zeroed;long x=v[0];usz count=0;
 while(true){long d=x%10;if(d>1)return -1;digits[count]=(char)d;count+=1;x/=10;if(x==0)break;if(count==8)return -1;}
 for(usz i=0;i<count;i++)rules[8-count+i]=digits[count-1-i];char[31][17] cells=zeroed;cells[0][15]=1;
 for(usz r=0;r<16;r++)for(usz c=0;c<31;c++){usz l=0;usz m=cells[r][c];usz rr=0;if(c>0)l=cells[r][c-1];if(c+1<31)rr=cells[r][c+1];usz p=(l<<2)|(m<<1)|rr;cells[r+1][c]=rules[7-p];}
 if(cap<1581||out==null)return -2;usz pos=0;for(usz r=0;r<17;r++)for(usz c=0;c<31;c++){char color=255;if(cells[r][c]==1)color=0;out[pos]=color;out[pos+1]=color;out[pos+2]=color;pos+=3;}return (long)pos;
}
