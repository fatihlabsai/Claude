// Procedural flame on a camera-facing quad. Colour is computed in the shader from a blackbody-style
// ramp (no gradient texture, no vertex colours -> avoids the WebGL green-flame bug).
// Alpha-blended variant: the main flame body keeps its orange/yellow structure instead of
// saturating to white when layers overlap.
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
#include "res://shaders/flame.gdshaderinc"
