export fn jaro_winkler(v:[*]const i64,n:usize)f64{
 if(n<2 or n>66)return -1.0e300;
 if(v[0]<0 or v[0]>32)return -1.0e300;
 const n1:usize=@intCast(v[0]);const p=1+n1;
 if(p>=n or v[p]<0 or v[p]>32)return -1.0e300;
 const n2:usize=@intCast(v[p]);if(n!=p+1+n2)return -1.0e300;
 for(0..n1)|i|{if(v[1+i]<0 or v[1+i]>127)return -1.0e300;}
 for(0..n2)|i|{if(v[p+1+i]<0 or v[p+1+i]>127)return -1.0e300;}
 const radius=@min(n1,n2)/2;var used_right:[32]bool=@splat(false);var first:[32]i64=@splat(0);var ca:usize=0;
 for(0..n1)|i|{const lo=if(i>radius)i-radius else 0;const hi=@min(i+radius+1,n2);for(lo..hi)|j|{if(!used_right[j] and v[1+i]==v[p+1+j]){used_right[j]=true;first[ca]=v[1+i];ca+=1;break;}}}
 var used_left:[32]bool=@splat(false);var second:[32]i64=@splat(0);var cb:usize=0;
 for(0..n2)|i|{const lo=if(i>radius)i-radius else 0;const hi=@min(i+radius+1,n1);for(lo..hi)|j|{if(!used_left[j] and v[p+1+i]==v[1+j]){used_left[j]=true;second[cb]=v[p+1+i];cb+=1;break;}}}
 var trans:usize=0;for(0..@min(ca,cb))|i|{if(first[i]!=second[i])trans+=1;}trans/=2;
 var jr:f64=0;if(ca>0){const m:@TypeOf(@as(f64,0))=@floatFromInt(ca);jr=(m/@as(f64,@floatFromInt(n1))+m/@as(f64,@floatFromInt(n2))+(m-@as(f64,@floatFromInt(trans)))/m)/3.0;}
 var prefix:usize=0;while(prefix<4 and prefix<n1 and prefix<n2 and v[1+prefix]==v[p+1+prefix]) : (prefix+=1) {}
 return jr+0.1*@as(f64,@floatFromInt(prefix))*(1.0-jr);
}
