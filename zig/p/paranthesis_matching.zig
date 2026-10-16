export fn paranthesis_matching(v:[*c]const i64,n:usize)i64{
 if(v==null||n<2||n>100||v[0]<1||v[0]>99||n!=@as(usize,@intCast(v[0]))+1)return -1;
 var st:[99]i64=undefined;var sp:usize=0;
 for(1..n)|i|{const x=v[i];if(x<33 or x>126)return -1;if(x==40 or x==123 or x==91 or x==60){st[sp]=x;sp+=1;}else if(x==41 or x==125 or x==93 or x==62){const want:i64=if(x==41)40 else if(x==125)123 else if(x==93)91 else 60;if(sp==0)return 0;sp-=1;if(st[sp]!=want)return 0;}else return 0;}
 return if(sp==0)1 else 0;
}
