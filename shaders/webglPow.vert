#version 300 es
precision highp float;
layout (location=0) in vec4 position;
layout (location=1) in vec2 uv;

out vec2 uv_pos;

void main() {
  uv_pos = uv;
  gl_Position = position;
}