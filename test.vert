uniform mat4 gl_ModelViewMatrix;
uniform mat4 gl_ProjectionMatrix;

attribute vec4 gl_Vertex;
uniform vec3 lol;

attribute vec4 gl_MultiTexCoord0;

uniform mat4 gl_TextureMatrix[gl_MaxTextureCoords];

void main() {
	vec4 asd = gl_Vertex;
	asd.x *= (1.0 + 0.3 * sin(3.0 * lol.x));
	gl_TexCoord[0] = gl_TextureMatrix[0] * gl_MultiTexCoord0;
	gl_Position = gl_ProjectionMatrix * gl_ModelViewMatrix * asd;
}
