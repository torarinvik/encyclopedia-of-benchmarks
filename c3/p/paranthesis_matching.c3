module paranthesis_matching;
fn long paranthesis_matching(long* v,usz n) @export("paranthesis_matching") {
 if(v==null||n<2||n>100)return -1;long count=v[0];if(count<1||count>99||n!=(usz)(count+1))return -1;
 char[99] st;usz sp=0;
 for(usz i=1;i<n;i+=1){long x=v[i];if(x<33||x>126)return -1;if(x==40||x==123||x==91||x==60){st[sp]=(char)x;sp+=1;}else if(x==41||x==125||x==93||x==62){char want=x==41?'(':x==125?'{':x==93?'[':'<';if(sp==0)return 0;sp-=1;if(st[sp]!=want)return 0;}else return 0;}
 return sp==0?1:0;
}
