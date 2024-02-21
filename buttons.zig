const shapes = @import("shapes.zig");

const Vec2   = @Vector(2, f32);
const Color = [4] u8;

pub const Button = struct {
    hovering   : bool,
    width      : f32,
    height     : f32,
    pos        : Vec2,
    color1_def : Color,
    color2_def : Color,
    color1_hov : Color,
    color2_hov : Color,
};

pub fn render_arrow(b : Button, arrow_is_pointing_left : bool) void {
    // Convert the direction to +1 or -1.
    const dir : f32 = if (arrow_is_pointing_left) 1 else -1;
    const background_color = if (b.hovering) b.color1_hov else b.color1_def;
    const detail_color     = if (b.hovering) b.color2_hov else b.color2_def;
    // Background first.    
    shapes.draw_centered_rect(b.pos, b.width, b.height, background_color);
    // Draw arrow body.
    shapes.draw_centered_rect(b.pos + Vec2{dir * 0.1 * b.width, 0}, 0.5 * b.width, 0.4 * b.height, detail_color);
    // Draw arrowhead triangle.
    const p1 = Vec2{b.pos[0] - dir * 0.4 * b.width, b.pos[1]};
    const p2 = Vec2{b.pos[0] - dir * 0.1 * b.width, b.pos[1] - 0.4 * b.height};
    const p3 = Vec2{b.pos[0] - dir * 0.1 * b.width, b.pos[1] + 0.4 * b.height};
    shapes.draw_triangle(p1, p2, p3, detail_color);
}

pub fn render_menu_button(b : Button) void {
    const square_length       = 0.7 * b.height;
    const subrectangle_height = 0.2 * square_length;
    const rect_pos = [3] Vec2 {
        b.pos + Vec2{0,  2 * subrectangle_height},
        b.pos + Vec2{0,  0 * subrectangle_height},
        b.pos + Vec2{0, -2 * subrectangle_height},
    };
    const background_color = if (b.hovering) b.color1_hov else b.color1_def;
    const detail_color     = if (b.hovering) b.color2_hov else b.color2_def;
    // Background first.    
    shapes.draw_centered_rect(b.pos, b.width, b.height, background_color);
    // Draw the three rectangles.
    for (rect_pos) |pos| {
        shapes.draw_centered_rect(pos, square_length, subrectangle_height, detail_color);
    }
}

pub fn render_bordered_rect(b : Button) void {
    const background_color = if (b.hovering) b.color1_hov else b.color1_def;
    const detail_color     = if (b.hovering) b.color2_hov else b.color2_def;
    const border_depth     = 0.1 * b.height;
    const inner_width      = b.width  - 2 * border_depth;
    const inner_height     = b.height - 2 * border_depth;
    
    shapes.draw_centered_rect(b.pos, b.width, b.height, detail_color);
    shapes.draw_centered_rect(b.pos, inner_width, inner_height, background_color);
}

pub fn set_hover_status(pos : Vec2, button : *Button) void {
    const button_center = button.pos;
    const xpos = pos[0];
    const ypos = pos[1];
    const in_rect = @fabs(xpos - button_center[0]) < 0.5 * button.width and @fabs(ypos - button_center[1]) < 0.5 * button.height;
    button.hovering = in_rect;
}
