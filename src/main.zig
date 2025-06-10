const std = @import("std");
const rl = @import("raylib");

var allocator = std.heap.page_allocator;

//
const cell_width = 20;
const ball_radius = 5;

comptime {
    if (ball_radius * 2 + 1 > cell_width) {
        @compileError("Your ball should fit in one cell.");
    }
}

const m = 9 * 3; // rows
const n = 16 * 3; // columns

const screen_width = cell_width * n;
const screen_height = cell_width * m;

const light_grey = rl.Color{ .r = 0xF0, .g = 0xF0, .b = 0xF0, .a = 0xFF };

// Custom Types
const Direction = struct {
    di: i8,
    dj: i8,

    const origin: Direction = .{ .dj = 0, .di = 0 }; // Origin
    const north: Direction = .{ .dj = 0, .di = -1 }; // North
    const south: Direction = .{ .dj = 0, .di = 1 }; // South
    const east: Direction = .{ .dj = 1, .di = 0 }; // East
    const west: Direction = .{ .dj = -1, .di = 0 }; // West
    const north_east: Direction = .{ .dj = 1, .di = -1 }; // North-East
    const south_east: Direction = .{ .dj = 1, .di = 1 }; // South-East
    const south_west: Direction = .{ .dj = -1, .di = 1 }; // South-West
    const north_west: Direction = .{ .dj = -1, .di = -1 }; // North-West

    const all: [8]Direction = .{
        .origin,
        .north,
        .south,
        .east,
        .west,
        .north_east,
        .south_east,
        .south_west,
        .north_west,
    };
};

// Game State
// ----------
// Nota: raylib uses i32 for coordinates.

const Point = struct {
    x: i32,
    y: i32,
};

const BoundingBox = struct {
    min: Point,
    max: Point,
    fn contains(self: BoundingBox, point: Point) bool {
        return (point.x >= self.min.x and point.x <= self.max.x and
            point.y >= self.min.y and point.y <= self.max.y);
    }
    fn intersect(self: BoundingBox, other: BoundingBox) bool {
        return !(self.max.x < other.min.x or self.min.x > other.max.x or
            self.max.y < other.min.y or self.min.y > other.max.y);
    }
};

const Cell = struct {
    i: i32,
    j: i32,

    const width: i32 = cell_width;

    fn fromPoint(point: Point) Cell {
        return .{ @divFloor(point.y, cell_width), @divFloor(point.x, cell_width) };
    }

    fn boundingBox(self: Cell) BoundingBox {
        return .{
            .min = .{ .x = self.j * cell_width, .y = self.i * cell_width },
            .max = .{ .x = (self.j + 1) * cell_width - 1, .y = (self.i + 1) * cell_width - 1 },
        };
    }
};

const Ball = struct {
    x: i32,
    y: i32,
    dir: Direction,

    const radius: i32 = ball_radius;

    fn boundingBox(self: Ball) BoundingBox {
        return .{
            .min = .{ .x = self.x - Ball.radius, .y = self.y - Ball.radius },
            .max = .{ .x = self.x + Ball.radius, .y = self.y + Ball.radius },
        };
    }
};

const State = struct {
    ball: Ball = .{ .x = 100 + ball_radius, .y = ball_radius + 200, .dir = .south_east },
    blocks: [m][n]bool = .{.{true} ** n} ** m,
};

var state = State{};

fn drawGrid() void {
    var k: i32 = 0;
    var l: i32 = undefined;
    while (k < m) : (k += 1) {
        l = 0;
        while (l < n) : (l += 1) {
            if (@mod(k + l, 2) == 0) {
                rl.drawRectangle(
                    l * cell_width,
                    k * cell_width,
                    cell_width,
                    cell_width,
                    light_grey,
                );
            }
        }
    }
}

fn ij(x: i32, y: i32) struct { i32, i32 } {
    return .{ @divFloor(y, cell_width), @divFloor(x, cell_width) };
}

fn xy(i: i32, j: i32) struct { i32, i32 } {
    return .{ j * cell_width + cell_width / 2, i * cell_width + cell_width / 2 };
}

fn directionsNeighbouringBlocks() []Direction {}

fn drawBlocks() void {
    var k: u16 = 0;
    var l: u16 = undefined;
    while (k < m) : (k += 1) {
        l = 0;
        while (l < n) : (l += 1) {
            if (state.blocks[k][l]) {
                rl.drawRectangle(
                    l * cell_width,
                    k * cell_width,
                    cell_width,
                    cell_width,
                    .black,
                );
            }
        }
    }
}

fn drawBall() void { // Simpler collision model
    return rl.drawCircle(state.ball.x, state.ball.y, Ball.radius, .red);
}

fn collider_blocks(x: i32, y: i32) [3][3]bool {
    const i, const j = ij(x, y);
    var blocks: [3][3]bool = .{.{false} ** 3} ** 3;
    const ball_bounding_box = state.ball.boundingBox();
    for (0..3) |di| {
        for (0..3) |dj| {
            const i_ = i + @as(i32, @intCast(di)) - 1;
            const j_ = j + @as(i32, @intCast(dj)) - 1;
            if (i_ < 0 or i_ >= m or j_ < 0 or j_ >= n or state.blocks[@intCast(i_)][@intCast(j_)]) {
                // need to test if collision with the ball
                const cell = Cell{ .i = i_, .j = j_ };
                if (ball_bounding_box.intersect(cell.boundingBox())) {
                    blocks[di][dj] = true;
                }
            }
        }
    }
    return blocks;
}

pub fn main() !void {
    rl.initWindow(screen_width, screen_height, "Breakout");
    defer rl.closeWindow();

    const ball = &state.ball;

    rl.setTargetFPS(120);
    while (!rl.windowShouldClose()) {
        ball.x += ball.dir.dj;
        ball.y += ball.dir.di;
        const i, const j = ij(ball.x, ball.y);
        if (i >= 0 and i < m and j >= 0 and j < n) {
            state.blocks[@intCast(i)][@intCast(j)] = false;
        }
        const colliders = collider_blocks(ball.x, ball.y);

        // TODO: adapt for 0..2
        out: for ([3]i32{ -1, 0, 1 }) |di| {
            for ([3]i32{ -1, 0, 1 }) |dj| {
                if (colliders[@intCast(di + 1)][@intCast(dj + 1)]) {
                    if (di != 0) {
                        ball.dir.di = -ball.dir.di; // bounce vertically
                        if (i + di >= 0 and i + di < m and j + dj >= 0 and j + dj < n) {
                            state.blocks[@intCast(i + di)][@intCast(j + dj)] = false;
                        }
                        break :out;
                    }
                    if (dj != 0) {
                        ball.dir.dj = -ball.dir.dj; // bounce horizontally
                        if (i + di >= 0 and i + di < m and j + dj >= 0 and j + dj < n) {
                            state.blocks[@intCast(i + di)][@intCast(j + dj)] = false;
                        }
                        break :out;
                    }
                }
            }
        }

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(.white);
        drawGrid();
        drawBlocks();
        drawBall();
        rl.drawFPS(10, 10);
    }
}
