import processing.*;
import processing.core.*;
import java.util.*;
import processing.opengl.*;

import com.sun.opengl.cg.*;
import javax.media.opengl.*;
import com.sun.opengl.util.*;
import java.nio.*;
import processing.opengl.*;
import saito.objloader.*;

public class Player extends GameObject {
	GLSL glsl;
	LinkedList<Integer> keyHistory = new LinkedList<Integer>();
	Player(PVector p, PVector d, PVector u, World w, PApplet pa, OBJModel model) {
		super(p, d, u, w, pa, model);
		glsl = new GLSL(pa);
		glsl.loadVertexShader("test.vert");
		glsl.loadFragmentShader("test.frag");
		glsl.useShaders();
	}
	void apply(PApplet pa) {
		PVector e = PVector.sub(pos, PVector.mult(dir, 4));
		e.add(PVector.mult(up, 2));
		int s=100;
		pa.camera(s*e.x, s*e.y, s*e.z, s*pos.x, s*pos.y, s*pos.z, -up.x, -up.y, -up.z);
	}
	void update(float dt) {
		super.update(dt);
		if (animation == null && !keyHistory.isEmpty()) {
			processKey(keyHistory.removeFirst());
		}
	}
	void pressKey(char key) {
		keyHistory.addLast((int)key);
		if (key == ' ') {
			keyHistory.clear();
			speed = normalspeed;
		}
	}
	void processKey(int key) {
		switch (key) {
			case 'i': walk(1); break;
			case 'k': walk(-1); break;
			case 'j': turn((float)Math.PI/2); break;
			case 'l': turn(-(float)Math.PI/2); break;
			case 'i' - 'a' + 1: superwalk(1); break;
			case 'k' - 'a' + 1: superwalk(-1); break;
			case 'f': speed = fastspeed; break;
			case 's': speed = normalspeed; break;
		}
	}
	
	void superwalk(int where) {
		int w = where < 0 ? -1 : 1;
		keyHistory.add((int)'f');
		for (int i = 1; ; i++) {
			PVector dest = PVector.add(pos, PVector.mult(dir, w * i));
			if (hitCheck(dest, where, false) || dropCheck(dest, where, false)) {
				if (i == 1) keyHistory.add(where < 0 ? (int)'k' : (int)'i');
				break;
			}
			keyHistory.add(where < 0 ? (int)'k' : (int)'i');
		}
		keyHistory.add((int)'s');
	}
	
	float zing = 0;
	void render(PGraphics pa, PImage tex) {
		zing += 0.1;
		glsl.startShader();
		glsl.uniform3f(glsl.getUniformLocation("lol"), zing, 0, 0);
		mdl.draw();
		glsl.endShader();
	}
}

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
