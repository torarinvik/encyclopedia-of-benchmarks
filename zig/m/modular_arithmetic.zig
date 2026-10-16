export fn modular_arithmetic(input:?[*]const i64,length:usize)i64{
 if(input==null or length!=4)return -1;const v=input.?[0..4];const op=v[0];const m=v[1];const a=v[2];const b=v[3];
 if(op<0 or op>2 or m<1 or m>1_000_000 or a<0 or a>=m or b<0 or b>=m)return -1;
 if(op==0)return @rem(@rem(a,m)+@rem(b,m),m);if(op==1)return @rem(@rem(a,m)-@rem(b,m)+m,m);return @rem(@rem(a,m)*@rem(b,m),m);
}
