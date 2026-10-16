export fn quadratic_residue(input: ?[*]const i64, length: usize) i64 {
 if(input==null or length!=2)return -1; const v=input.?; const a=v[0]; const p=v[1];
 if(!(p==3 or p==5 or p==7 or p==11 or p==13 or p==17 or p==19 or p==23 or p==29 or p==31 or p==37 or p==41 or p==43 or p==47 or p==53) or a<0 or a>=p)return -1;
 if(a==0)return 0; var r:i64=1; var b=a; var e=(p-1)/2; while(e>0):(e>>=1){if(e&1!=0)r=@mod(r*b,p); b=@mod(b*b,p);} return if(r==1) 1 else -1;
}
