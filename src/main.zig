const std = @import("std");
const rl = @import("raylib");

// Comptime
const cell_width = 20;
const ball_radius = 5;
const m = 9 * 3; // rows
const n = 16 * 3; // columns

const screen_width = cell_width * n;
const screen_height = cell_width * m;

const light_grey = rl.Color{ .r = 0xF0, .g = 0xF0, .b = 0xF0, .a = 0xFF };

// Custom Types
const Direction = struct {
    dx: i8,
    dy: i8,

    pub const north: Direction = .{ .dx = 0, .dy = -1 }; // North
    pub const south: Direction = .{ .dx = 0, .dy = 1 }; // South
    pub const east: Direction = .{ .dx = 1, .dy = 0 }; // East
    pub const west: Direction = .{ .dx = -1, .dy = 0 }; // West
    pub const north_east: Direction = .{ .dx = 1, .dy = -1 }; // North-East
    pub const south_east: Direction = .{ .dx = 1, .dy = 1 }; // South-East
    pub const south_west: Direction = .{ .dx = -1, .dy = 1 }; // South-West
    pub const north_west: Direction = .{ .dx = -1, .dy = -1 }; // North-West
};

// Game State
// ----------
// Nota: raylib uses i32 for coordinates.
var x: i32 = 100 + ball_radius;
var y: i32 = ball_radius;
var dir = Direction.south_east;
var blocks: [m]([n]bool) = .{.{true} ** n} ** m;

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

fn drawBlocks() void {
    var k: u16 = 0;
    var l: u16 = undefined;
    while (k < m) : (k += 1) {
        l = 0;
        while (l < n) : (l += 1) {
            if (blocks[k][l]) {
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

fn drawBall() void {
    rl.drawCircle(x, y, ball_radius, .red);
}

// TODO: detect in what block we are (center) as well as the other that
//       we touch. Or maybe just the ones we touch and a list of directions
//       for the neighbours we touch?

fn detectCollision() struct { i32, i32 } {
    return .{ @divFloor(y, cell_width), @divFloor(x, cell_width) }; // not exact ...
}

pub fn main() !void {
    rl.initWindow(screen_width, screen_height, "Breakout");
    defer rl.closeWindow();

    rl.setTargetFPS(20);
    while (!rl.windowShouldClose()) {
        x += dir.dx;
        y += dir.dy;
        const i, const j = detectCollision();
        std.debug.print("Ball at ({d}, {d})\n", .{ i, j });
        blocks[@intCast(i)][@intCast(j)] = false; // remove the block we hit

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(.white);
        drawGrid();
        drawBlocks();
        drawBall();
    }
}
