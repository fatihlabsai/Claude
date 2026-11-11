// Procedural flame on a camera-facing quad. Colour is computed in the shader from a blackbody-style
// ramp (no gradient texture, no vertex colours -> avoids the WebGL green-flame bug).
// Additive variant: flame licks (particles).
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
#include "res://shaders/flame.gdshaderinc"
