module parenthesis;
fn long parenthesis(long* v,usz n) @export("parenthesis"){if(v==null||n<1||n>129||v[0]<0||v[0]>128||n!=(usz)v[0]+1)return -1;long balance=0;for(usz i=1;i<n;i++){long x=v[i];if(x<0||x>127)return -1;if(x==40)balance+=1;else if(x==41){balance-=1;if(balance<0)return 0;}}return balance==0;}
