const MIN_BODIES: usize = 2;
const MAX_BODIES: usize = 16;
const MAX_NODES: usize = 1024;
const MAX_DEPTH: usize = 16;

#[derive(Clone, Copy)]
struct Body { position: [f64; 3], mass: f64 }

#[derive(Clone, Copy)]
struct Cell { body: i32, child: [i32; 8], mass: f64, center: [f64; 3] }

impl Cell {
    fn empty() -> Self { Self { body: -1, child: [-1; 8], mass: 0.0, center: [0.0; 3] } }
}

fn octant(position: [f64; 3], center: [f64; 3]) -> usize {
    (usize::from(position[0] >= center[0])) |
    (usize::from(position[1] >= center[1]) << 1) |
    (usize::from(position[2] >= center[2]) << 2)
}

fn next_center(center: [f64; 3], half: f64, child: usize) -> [f64; 3] {
    [
        center[0] + if child & 1 != 0 { half / 2.0 } else { -half / 2.0 },
        center[1] + if child & 2 != 0 { half / 2.0 } else { -half / 2.0 },
        center[2] + if child & 4 != 0 { half / 2.0 } else { -half / 2.0 },
    ]
}

fn insert(cells: &mut Vec<Cell>, index: usize, body_index: usize,
          center: [f64; 3], half: f64, depth: usize, bodies: &[Body]) -> bool {
    let old_body = cells[index].body;
    if old_body == -1 { cells[index].body = body_index as i32; return true; }
    if depth >= MAX_DEPTH { return false; }
    if old_body >= 0 { cells[index].body = -2; }
    let items = if old_body >= 0 { vec![old_body as usize, body_index] } else { vec![body_index] };
    for item in items {
        let child = octant(bodies[item].position, center);
        let child_index = if cells[index].child[child] < 0 {
            if cells.len() >= MAX_NODES { return false; }
            let created = cells.len();
            cells.push(Cell::empty());
            cells[index].child[child] = created as i32;
            created
        } else { cells[index].child[child] as usize };
        if !insert(cells, child_index, item, next_center(center, half, child), half / 2.0, depth + 1, bodies) {
            return false;
        }
    }
    true
}

fn aggregate(cells: &mut [Cell], index: usize, bodies: &[Body]) {
    let body = cells[index].body;
    if body >= 0 {
        let source = bodies[body as usize];
        cells[index].mass = source.mass;
        cells[index].center = source.position;
        return;
    }
    let mut mass = 0.0;
    let mut weighted = [0.0; 3];
    for child in 0..8 {
        let child_index = cells[index].child[child];
        if child_index < 0 { continue; }
        let child_index = child_index as usize;
        aggregate(cells, child_index, bodies);
        mass += cells[child_index].mass;
        for axis in 0..3 { weighted[axis] += cells[child_index].mass * cells[child_index].center[axis]; }
    }
    cells[index].mass = mass;
    for axis in 0..3 { cells[index].center[axis] = weighted[axis] / mass; }
}

fn interact(mass: f64, position: [f64; 3], query: [f64; 3], eps_sq: f64,
            potential: &mut f64, acceleration: &mut [f64; 3]) {
    let d = [position[0]-query[0], position[1]-query[1], position[2]-query[2]];
    let r2 = d[0]*d[0] + d[1]*d[1] + d[2]*d[2] + eps_sq;
    let r = r2.sqrt();
    let contribution = mass / r;
    *potential -= contribution;
    let scale = contribution / r2;
    for axis in 0..3 { acceleration[axis] += d[axis] * scale; }
}

fn walk(cells: &[Cell], index: usize, side: f64, theta_sq: f64, query: [f64; 3], eps_sq: f64,
        potential: &mut f64, acceleration: &mut [f64; 3], bodies: &[Body]) {
    let cell = cells[index];
    if cell.body >= 0 {
        let body = bodies[cell.body as usize];
        interact(body.mass, body.position, query, eps_sq, potential, acceleration);
        return;
    }
    let d = [cell.center[0]-query[0], cell.center[1]-query[1], cell.center[2]-query[2]];
    let distance_sq = d[0]*d[0] + d[1]*d[1] + d[2]*d[2];
    if theta_sq * distance_sq < side * side {
        for child in 0..8 {
            let child_index = cell.child[child];
            if child_index >= 0 { walk(cells, child_index as usize, side/2.0, theta_sq, query, eps_sq, potential, acceleration, bodies); }
        }
    } else { interact(cell.mass, cell.center, query, eps_sq, potential, acceleration); }
}

#[no_mangle]
pub unsafe extern "C" fn olden_bh(input: *const f64, input_length: usize,
    output: *mut f64, output_capacity: usize) -> i64 {
    if input.is_null() || input_length < 6 { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, input_length) };
    let requested_count = values[0];
    let theta = values[1];
    let softening = values[2];
    if !(requested_count >= MIN_BODIES as f64 && requested_count <= MAX_BODIES as f64) || requested_count.fract()!=0.0 ||
       !(0.0..=2.0).contains(&theta) || !(0.0..=1.0).contains(&softening) { return -1; }
    let count = requested_count as usize;
    if input_length != 6 + 4*count { return -1; }
    let query = [values[3], values[4], values[5]];
    let mut bodies = [Body { position: [0.0;3], mass: 0.0 }; MAX_BODIES];
    let mut minima = [32.0; 3];
    let mut maxima = [-32.0; 3];
    for body in 0..count {
        for axis in 0..3 {
            let coordinate = values[6+4*body+axis];
            if !coordinate.is_finite() || coordinate.fract()!=0.0 || !(-32.0..=32.0).contains(&coordinate) || !(-32.0..=32.0).contains(&query[axis]) { return -1; }
            bodies[body].position[axis] = coordinate;
            minima[axis] = minima[axis].min(coordinate);
            maxima[axis] = maxima[axis].max(coordinate);
        }
        let mass = values[9+4*body];
        if !(1.0..=16.0).contains(&mass) { return -1; }
        bodies[body].mass = mass;
    }
    for a in 0..count { for b in a+1..count { if bodies[a].position == bodies[b].position { return -1; } } }
    let inside = (0..3).all(|axis| query[axis] >= minima[axis] && query[axis] <= maxima[axis]);
    if inside { return -1; }
    if output.is_null() || output_capacity < 4 { return -2; }
    let side = (maxima[0]-minima[0]).max((maxima[1]-minima[1]).max(maxima[2]-minima[2]));
    if side <= 0.0 { return -1; }
    let center = [(minima[0]+maxima[0])/2.0, (minima[1]+maxima[1])/2.0, (minima[2]+maxima[2])/2.0];
    let mut cells = Vec::with_capacity(MAX_NODES);
    cells.push(Cell::empty());
    for body in 0..count { if !insert(&mut cells, 0, body, center, side/2.0, 0, &bodies[..count]) { return -1; } }
    aggregate(&mut cells, 0, &bodies[..count]);
    let mut potential = 0.0; let mut acceleration = [0.0;3];
    walk(&cells, 0, side, theta*theta, query, softening*softening, &mut potential, &mut acceleration, &bodies[..count]);
    unsafe { *output = potential; *output.add(1) = acceleration[0]; *output.add(2) = acceleration[1]; *output.add(3) = acceleration[2]; }
    4
}
