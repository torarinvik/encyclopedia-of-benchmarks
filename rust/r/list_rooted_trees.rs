const MAX_VERTICES: usize = 7;
const MAX_SHAPES: usize = 48;
const MAX_WIDTH: usize = 15;
const MAX_CANDIDATES: usize = 37;
const MAX_OUTPUT: usize = 674;

#[derive(Clone, Copy)]
struct Candidate {
    size: usize,
    text: [u8; MAX_WIDTH],
}

impl Candidate {
    const EMPTY: Self = Self {
        size: 0,
        text: [0; MAX_WIDTH],
    };
}

struct Generator {
    shapes: [[[u8; MAX_WIDTH]; MAX_SHAPES]; MAX_VERTICES + 1],
    counts: [usize; MAX_VERTICES + 1],
    target: usize,
}

impl Generator {
    fn new() -> Self {
        Self {
            shapes: [[[0; MAX_WIDTH]; MAX_SHAPES]; MAX_VERTICES + 1],
            counts: [0; MAX_VERTICES + 1],
            target: 0,
        }
    }

    fn enumerate_multisets(
        &mut self,
        candidates: &[Candidate],
        start: usize,
        remaining: usize,
        children: &mut [u8; MAX_WIDTH],
        child_length: usize,
    ) {
        if remaining == 0 {
            let index = self.counts[self.target];
            if index >= MAX_SHAPES {
                return;
            }
            let mut shape = [0u8; MAX_WIDTH];
            shape[0] = b'(';
            shape[1..1 + child_length]
                .copy_from_slice(&children[..child_length]);
            shape[child_length + 1] = b')';
            self.shapes[self.target][index] = shape;
            self.counts[self.target] = index + 1;
            return;
        }

        for index in start..candidates.len() {
            let candidate = candidates[index];
            if candidate.size > remaining {
                continue;
            }
            let encoded_length = 2 * candidate.size;
            children[child_length..child_length + encoded_length]
                .copy_from_slice(&candidate.text[..encoded_length]);
            self.enumerate_multisets(
                candidates,
                index,
                remaining - candidate.size,
                children,
                child_length + encoded_length,
            );
        }
    }

    fn build(&mut self, maximum: usize) {
        self.counts[1] = 1;
        self.shapes[1][0][0] = b'(';
        self.shapes[1][0][1] = b')';

        for target in 2..=maximum {
            self.target = target;
            let mut candidates = [Candidate::EMPTY; MAX_CANDIDATES];
            let mut candidate_count = 0;
            for size in 1..target {
                for index in 0..self.counts[size] {
                    candidates[candidate_count] = Candidate {
                        size,
                        text: self.shapes[size][index],
                    };
                    candidate_count += 1;
                }
            }
            candidates[..candidate_count]
                .sort_unstable_by(|left, right| left.text.cmp(&right.text));

            let mut children = [0u8; MAX_WIDTH];
            self.enumerate_multisets(
                &candidates[..candidate_count],
                0,
                target - 1,
                &mut children,
                0,
            );
            self.shapes[target][..self.counts[target]].sort_unstable();
        }
    }
}

fn valid_vertices(value: i64) -> Option<usize> {
    if (1..=MAX_VERTICES as i64).contains(&value) {
        Some(value as usize)
    } else {
        None
    }
}

#[no_mangle]
pub unsafe extern "C" fn list_rooted_trees(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length != 1 {
        return -1;
    }
    let Some(vertices) = valid_vertices(*input) else {
        return -1;
    };

    let mut generator = Generator::new();
    generator.build(vertices);

    let count = generator.counts[vertices];
    let width = 2 * vertices;
    let needed = 2 + count * width;
    let mut staged = [0u8; MAX_OUTPUT];
    staged[0] = (count & 0xff) as u8;
    staged[1] = ((count >> 8) & 0xff) as u8;
    let mut position = 2;
    for shape in &generator.shapes[vertices][..count] {
        staged[position..position + width].copy_from_slice(&shape[..width]);
        position += width;
    }

    if output.is_null() || capacity < needed {
        return -2;
    }
    std::ptr::copy_nonoverlapping(staged.as_ptr(), output, needed);
    needed as i64
}
