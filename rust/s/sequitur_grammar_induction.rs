// Clean-room bounded deterministic Sequitur grammar profile.
#[derive(Clone, Copy)]
struct Duplicate { r1:usize, p1:usize, r2:usize, p2:usize, left:i32, right:i32 }
struct Grammar {
    symbols: [[i32;64];256],
    lengths: [usize;256],
    live: [bool;256],
    next_rule: usize,
}

impl Grammar {
    fn replace_pair(&mut self, rule:usize, position:usize, token:i32) {
        for i in position+2..self.lengths[rule] { self.symbols[rule][i-1]=self.symbols[rule][i]; }
        self.lengths[rule]-=1; self.symbols[rule][position]=token;
    }
    fn find_duplicate(&self) -> Option<Duplicate> {
        for r1 in 0..self.next_rule { if self.live[r1] {
            for p1 in 0..self.lengths[r1].saturating_sub(1) {
                let left=self.symbols[r1][p1]; let right=self.symbols[r1][p1+1];
                for r2 in r1..self.next_rule { if self.live[r2] {
                    let start=if r2==r1 {p1+2} else {0};
                    for p2 in start..self.lengths[r2].saturating_sub(1) {
                        if self.symbols[r2][p2]==left && self.symbols[r2][p2+1]==right {
                            return Some(Duplicate{r1,p1,r2,p2,left,right});
                        }
                    }
                }}
            }
        }}
        None
    }
    fn cleanup_one(&mut self) -> bool {
        for target in 1..self.next_rule { if self.live[target] {
            let token=256+target as i32; let mut count=0usize; let mut parent=0usize; let mut position=0usize;
            for rule in 0..self.next_rule { if self.live[rule] {
                for i in 0..self.lengths[rule] { if self.symbols[rule][i]==token {count+=1;parent=rule;position=i;} }
            }}
            if count==0 { self.live[target]=false; self.lengths[target]=0; return true; }
            if count==1 {
                let copy=self.symbols[target]; let replacement_length=self.lengths[target];
                let delta=replacement_length as isize-1; let old_length=self.lengths[parent];
                for i in (position+1..old_length).rev() { self.symbols[parent][(i as isize+delta) as usize]=self.symbols[parent][i]; }
                for i in 0..replacement_length { self.symbols[parent][position+i]=copy[i]; }
                self.lengths[parent]=(old_length as isize+delta) as usize;
                self.live[target]=false; self.lengths[target]=0; return true;
            }
        }}
        false
    }
    fn normalize(&mut self) {
        loop {
            while self.cleanup_one() {}
            let d=match self.find_duplicate() {Some(value)=>value,None=>return};
            let mut existing=None;
            for rule in 1..self.next_rule {
                if self.live[rule] && self.lengths[rule]==2 && self.symbols[rule][0]==d.left && self.symbols[rule][1]==d.right {existing=Some(rule);break;}
            }
            if let Some(rule)=existing {
                let (target,position)=if d.r1==rule && d.p1==0 {(d.r2,d.p2)} else {(d.r1,d.p1)};
                self.replace_pair(target,position,256+rule as i32);
            } else {
                let fresh=self.next_rule; self.next_rule+=1; self.live[fresh]=true; self.lengths[fresh]=2;
                self.symbols[fresh][0]=d.left;self.symbols[fresh][1]=d.right;
                self.replace_pair(d.r2,d.p2,256+fresh as i32);
                self.replace_pair(d.r1,d.p1,256+fresh as i32);
            }
        }
    }
}

#[no_mangle]
pub unsafe extern "C" fn sequitur_grammar_induction(input:*const i64,length:usize)->i64 {
    if input.is_null() || !(1..=66).contains(&length) {return -1;}
    let values=std::slice::from_raw_parts(input,length);
    if !(0..=64).contains(&values[0]) || length!=values[0] as usize+1 {return -1;}
    let n=values[0] as usize;
    if values[1..].iter().any(|&x| !(0..=255).contains(&x)) {return -1;}
    let mut g=Grammar{symbols:[[0;64];256],lengths:[0;256],live:[false;256],next_rule:1};g.live[0]=true;
    for &symbol in &values[1..1+n] {let pos=g.lengths[0];g.symbols[0][pos]=symbol as i32;g.lengths[0]+=1;g.normalize();}
    let mut rules=0i64;let mut symbols=0i64;
    for rule in 0..g.next_rule {if g.live[rule] {if rule!=0 {rules+=1;}symbols+=g.lengths[rule] as i64;}}
    1000*rules+symbols
}
