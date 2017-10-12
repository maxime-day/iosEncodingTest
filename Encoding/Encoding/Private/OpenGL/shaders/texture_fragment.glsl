precision mediump float;

uniform vec4 v_Color;
uniform sampler2D u_Texture;
varying vec2 v_TexCoordinate;

void main() {
    
    //vec4 color = vec4(1.0, 0.5, 1.0, 1.0);
    //gl_FragColor = (color * texture2D(u_Texture, v_TexCoordinate));
    
    //gl_FragColor = texture2D(u_Texture, v_TexCoordinate);
    
    //gl_FragColor = v_Color;
    
    //gl_FragColor = vec4(1.0, 0.5, 1.0, 1.0);
    
    // This is the correct one
    gl_FragColor = (v_Color * texture2D(u_Texture, v_TexCoordinate));
    
}
