#version 300 es
// Cardboard side-by-side: the centre square of the monitor, drawn twice.
// cardboard-sbs copies this file and fills in ASPECT from the focused monitor.
precision highp float;

in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

const float ASPECT = 16.0 / 9.0; // @ASPECT@

void main() {
    // Each eye is a square half the screen wide, centred vertically.
    float eyeH = 0.5 * ASPECT;
    float top = (1.0 - eyeH) * 0.5;
    if (v_texcoord.y < top || v_texcoord.y > top + eyeH) {
        fragColor = vec4(0.0, 0.0, 0.0, 1.0);
        return;
    }

    vec2 eye = vec2(fract(v_texcoord.x * 2.0), (v_texcoord.y - top) / eyeH);
    float srcW = 1.0 / ASPECT;
    fragColor = texture(tex, vec2(0.5 - srcW * 0.5 + eye.x * srcW, eye.y));
}
