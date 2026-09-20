#version 320 es
// Maple Saturation Shader — Hyprland
// Saturation: 2.25 (solo eDP-1 / wl_output 0; HDMI sin efecto)
precision mediump float;

in vec2 v_texcoord;
uniform sampler2D tex;
uniform int wl_output;
layout(location = 0) out vec4 fragColor;

void main() {
    vec4 color = texture(tex, v_texcoord);
    if (wl_output != 0) {
        fragColor = color;
        return;
    }
    float grey = dot(color.rgb, vec3(0.2126, 0.7152, 0.0722));
    vec3 saturated = mix(vec3(grey), color.rgb, 2.25);
    fragColor = vec4(saturated, color.a);
}