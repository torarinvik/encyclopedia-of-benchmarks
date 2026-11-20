const OPS: usize = 40;
const WORDS: usize = 82;
const N: usize = 256;

struct Table {
    dir: [u8; N], keys: [[u8; 2]; N], count: [u8; N], depth: [u8; N], active: [bool; N],
    gd: usize, high: usize, buckets: usize, live: usize,
}
impl Table {
    fn new() -> Self {
        let mut t = Self { dir: [0; N], keys: [[0; 2]; N], count: [0; N], depth: [0; N], active: [false; N], gd: 1, high: 1, buckets: 2, live: 0 };
        t.dir[0] = 0; t.dir[1] = 1; t.active[0] = true; t.active[1] = true; t.depth[0] = 1; t.depth[1] = 1; t
    }
    fn bucket(&self, key: usize) -> usize { self.dir[key & ((1 << self.gd) - 1)] as usize }
    fn find(&self, b: usize, key: u8) -> Option<usize> { (0..self.count[b] as usize).find(|&s| self.keys[b][s] == key) }
    fn split(&mut self, b: usize) -> bool {
        let d = self.depth[b] as usize;
        if d >= 8 { return false; }
        if d == self.gd {
            let size = 1 << self.gd;
            for i in 0..size { self.dir[i + size] = self.dir[i]; }
            self.gd += 1; self.high = self.high.max(self.gd);
        }
        let Some(fresh) = self.active.iter().position(|&a| !a) else { return false; };
        self.active[fresh] = true; self.depth[b] = (d + 1) as u8; self.depth[fresh] = (d + 1) as u8;
        let old_count = self.count[b] as usize; let old = self.keys[b];
        self.count[b] = 0; self.count[fresh] = 0; self.keys[b] = [0; 2]; self.keys[fresh] = [0; 2];
        let bit = 1 << d; let size = 1 << self.gd;
        for i in 0..size { if self.dir[i] as usize == b && i & bit != 0 { self.dir[i] = fresh as u8; } }
        for &key in &old[..old_count] {
            let target = if key as usize & bit != 0 { fresh } else { b };
            let n = self.count[target] as usize; self.keys[target][n] = key; self.count[target] += 1;
        }
        self.buckets += 1; true
    }
    fn coalesce(&mut self, mut b: usize) {
        while self.depth[b] > 1 {
            let d = self.depth[b] as usize; let size = 1 << self.gd;
            let Some(rep) = (0..size).find(|&i| self.dir[i] as usize == b) else { break; };
            let p = rep & ((1 << d) - 1); let bp = p ^ (1 << (d - 1)); let buddy = self.dir[bp] as usize;
            if buddy == b || !self.active[buddy] || self.depth[buddy] as usize != d || self.count[b] + self.count[buddy] > 2 { break; }
            let (keep, drop) = if bp < p { (buddy, b) } else { (b, buddy) };
            let drop_n = self.count[drop] as usize; let keep_n = self.count[keep] as usize;
            for j in 0..drop_n { self.keys[keep][keep_n + j] = self.keys[drop][j]; }
            self.count[keep] += self.count[drop]; self.count[drop] = 0; self.keys[drop] = [0; 2];
            self.depth[keep] = (d - 1) as u8; self.active[drop] = false;
            for i in 0..size { if self.dir[i] as usize == drop { self.dir[i] = keep as u8; } }
            self.buckets -= 1; b = keep;
        }
        while self.gd > 1 {
            let half = 1 << (self.gd - 1);
            if (0..half).any(|i| self.dir[i] != self.dir[i + half]) { break; }
            self.gd -= 1;
        }
    }
}

fn solve(input: &[i64]) -> i64 {
    if input.is_empty() || input.len() > WORDS { return -1; }
    let qv = input[0]; if !(0..=OPS as i64).contains(&qv) { return -1; }
    let q = qv as usize; if input.len() != 1 + 2 * q { return -1; }
    for pair in input[1..].chunks_exact(2) { if !(0..=2).contains(&pair[0]) || !(0..=255).contains(&pair[1]) { return -1; } }
    let mut t = Table::new(); let mut success: u64 = 0;
    for pair in input[1..].chunks_exact(2) {
        let op = pair[0] as usize; let key = pair[1] as u8; let mut b = t.bucket(key as usize);
        let slot = t.find(b, key); let mut ok = 0u64;
        if op == 0 && slot.is_none() {
            while t.count[b] == 2 { if !t.split(b) { break; } b = t.bucket(key as usize); }
            if t.count[b] < 2 { let n = t.count[b] as usize; t.keys[b][n] = key; t.count[b] += 1; t.live += 1; ok = 1; }
        } else if op == 1 {
            if let Some(s) = slot { let n = t.count[b] as usize - 1; t.count[b] -= 1; t.keys[b][s] = t.keys[b][n]; t.keys[b][n] = 0; t.live -= 1; ok = 1; t.coalesce(b); }
        } else if op == 2 { ok = if slot.is_some() { 1 } else { 0 }; }
        success = (success << 1) | ok;
    }
    (success | ((t.buckets as u64) << 40) | ((t.gd as u64) << 49) | ((t.high as u64) << 53) | ((t.live as u64) << 57)) as i64
}

#[no_mangle]
pub unsafe extern "C" fn extendible_hashing_trace(input: *const i64, length: usize) -> i64 {
    if input.is_null() || !(1..=WORDS).contains(&length) { return -1; }
    let frame = unsafe { std::slice::from_raw_parts(input, length) };
    solve(frame)
}
