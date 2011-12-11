// ei omaa koodia; halusin vain kokeilla miten helposti omat shaderit onnistuvat processingilla; aika helposti.
import processing.core.*;
import processing.opengl.*;
import javax.media.opengl.*;
import com.sun.opengl.util.*;
import java.nio.*;

class GLSL {
	int programObject;
	GL gl;
	boolean vertexShaderEnabled;
	boolean vertexShaderSupported; 
	int vs;
	int fs;
	PApplet pa;

	GLSL(PApplet pa) {
		this.pa=pa;
		gl=((PGraphicsOpenGL)pa.g).gl;
		String extensions = gl.glGetString(GL.GL_EXTENSIONS);
		vertexShaderSupported = extensions.indexOf("GL_ARB_vertex_shader") != -1;
		vertexShaderEnabled = true;    
		programObject = gl.glCreateProgramObjectARB(); 
		vs=-1;
		fs=-1;
	}

	void loadVertexShader(String file) {
		String shaderSource=PApplet.join(pa.loadStrings(file),"\n");
		vs = gl.glCreateShaderObjectARB(GL.GL_VERTEX_SHADER_ARB);
		gl.glShaderSourceARB(vs, 1, new String[]{shaderSource},(int[]) null, 0);
		gl.glCompileShaderARB(vs);
		checkLogInfo(gl, vs);
		gl.glAttachObjectARB(programObject, vs); 
	}

	void loadFragmentShader(String file) {
		String shaderSource=PApplet.join(pa.loadStrings(file),"\n");
		fs = gl.glCreateShaderObjectARB(GL.GL_FRAGMENT_SHADER_ARB);
		gl.glShaderSourceARB(fs, 1, new String[]{shaderSource},(int[]) null, 0);
		gl.glCompileShaderARB(fs);
		checkLogInfo(gl, fs);
		gl.glAttachObjectARB(programObject, fs); 
	}

	int getAttribLocation(String name) {
		return(gl.glGetAttribLocationARB(programObject,name));
	}

	int getUniformLocation(String name) {
		return(gl.glGetUniformLocationARB(programObject,name));
	}

	void useShaders() {
		gl.glLinkProgramARB(programObject);
		gl.glValidateProgramARB(programObject);
		checkLogInfo(gl, programObject);
	}

	void startShader() {
		gl.glUseProgramObjectARB(programObject); 
	}

	void endShader() {
		gl.glUseProgramObjectARB(0); 
	}

	void checkLogInfo(GL gl, int obj) {
		IntBuffer iVal = BufferUtil.newIntBuffer(1);
		gl.glGetObjectParameterivARB(obj, GL.GL_OBJECT_INFO_LOG_LENGTH_ARB, iVal);

		int length = iVal.get();
		if (length <= 1) {
			return;
		}
		ByteBuffer infoLog = BufferUtil.newByteBuffer(length);
		iVal.flip();
		gl.glGetInfoLogARB(obj, length, iVal, infoLog);
		byte[] infoBytes = new byte[length];
		infoLog.get(infoBytes);
		pa.println("GLSL Validation >> " + new String(infoBytes));
	} 
	void uniform3f(int location, float v0, float v1, float v2) {
		gl.glUniform3fARB(location, v0, v1, v2);
	}
}
