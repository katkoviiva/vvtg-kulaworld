import processing.*;
import processing.core.*;
import java.util.*;
import processing.opengl.*;

import com.sun.opengl.cg.*;
import javax.media.opengl.*;
import com.sun.opengl.util.*;
import java.nio.*;
import processing.opengl.*;

public class Player {
	PVector pos, dir, up; // maailmakoordinaatistossa
	PMatrix3D rotstate = new PMatrix3D();
	World world;
	static final float normalspeed = 2.0f, fastspeed = 8.0f;
	float speed = normalspeed;
	int steps;
	
	LinkedList<Integer> keyHistory = new LinkedList<Integer>();
	
	PApplet pa;
	
	abstract class Animation {
		PVector opos, odir, oup;
		PMatrix3D orotstate;
		float time;
		Animation() { start(); }
		abstract void animate(/*Player player*/float time);
		void start() {
			opos = PVector.mult(pos, 1);
			odir = PVector.mult(dir, 1);
			oup = PVector.mult(up, 1);
			orotstate = new PMatrix3D(rotstate);
			time = 0;
		}
		boolean run(float dt) {
			time += dt * speed;
			if (time > 1) time = 1;
			animate(time);
			return time != 1;
		}
	}
	class Walk extends Animation {
		float spd;
		Walk(float s) { super(); spd = s; }
		void animate(float time) {
			pos = PVector.add(opos, PVector.mult(odir, spd * time));
			PMatrix3D mat = new PMatrix3D();
			mat.rotate(spd * time * (float)Math.PI / 2, 1, 0, 0);
			rotstate = new PMatrix3D(orotstate);
			rotstate.apply(mat);
			if (time == 1) world.visit(PVector.sub(pos, up));
		}
	}
	class FallRotation extends Animation {
		int where;
		FallRotation(int w) { super(); where = w; }
		void animate(float time) {
			PVector axis = oup.cross(odir);
			axis.mult(where);
			PMatrix3D rotmat = new PMatrix3D();
			rotmat.rotate(time * (float)Math.PI/2, axis.x, axis.y, axis.z);
			dir = rotmat.mult(odir, null);
			up = rotmat.mult(oup, null);
			PVector posdiff;
			if (where > 0)
				posdiff = PVector.mult(PVector.sub(odir, oup), time);
			else
				posdiff = PVector.mult(PVector.add(odir, oup), -time);
			pos = PVector.add(opos, posdiff);
		}
	}
	class HitRotation extends Animation {
		int where;
		HitRotation(int w) { super(); where = w; }
		void animate(float time) {
			PVector axis = oup.cross(odir);
			axis.mult(-where);
			PMatrix3D rotmat = new PMatrix3D();
			rotmat.rotate(time * (float)Math.PI/2, axis.x, axis.y, axis.z);
			dir = rotmat.mult(odir, null);
			up = rotmat.mult(oup, null);
			if (time == 1) world.visit(PVector.sub(pos, up));
			// TODO: pyöristä täällä lopuksi (animtime==1) nuo niin ettei mee tippaakaan vinoon
			// (tarvitseeko?)
		}
	}
	
	class Turn extends Animation {
		float turnang;
		Turn(float ang) {
			super();
			turnang = ang;
		}
		void animate(float time) {
			dir = odir;
			rot(time * turnang);
		}
	}
	
	Animation animation = null;
	GLSL glsl;
	Player(PVector p, PVector d, PVector u, World w, PApplet pa) {
		pos = p;
		dir = d;
		up = u;
		world = w;
		glsl = new GLSL(pa);
		glsl.loadVertexShader("test.vert");
		glsl.loadFragmentShader("test.frag");
		glsl.useShaders();
		this.pa=pa;
	}
	void apply(PApplet pa) {
		PVector e = PVector.sub(pos, PVector.mult(dir, 4));
		e.add(PVector.mult(up, 2));
		int s=100;
		pa.camera(s*e.x, s*e.y, s*e.z, s*pos.x, s*pos.y, s*pos.z, -up.x, -up.y, -up.z);
	}
	void update(float dt) {
		if (animation != null) {
			if (!animation.run(dt)) {
				animation = null;
			}
		} else {
			if (!keyHistory.isEmpty()) {
				processKey(keyHistory.removeFirst());
			}
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

	void walk(int where) {
		if (steps >= 0) steps++;
		PVector dest = PVector.add(pos, PVector.mult(dir, where));
		if (hitCheck(dest, where, true)) return;
		if (dropCheck(dest, where, true)) return;
		animation = new Walk(where);
	}
	
	boolean dropCheck(PVector p, int where, boolean anim) {
		if (!world.hasBlk(PVector.add(p, PVector.mult(up, -1)))) {
			if (anim) animation = new FallRotation(where);
			return true;
		}
		return false;
	}
	
	boolean hitCheck(PVector p, int where, boolean anim) {
		if (world.hasBlk(p)) {
			if (anim) animation = new HitRotation(where);
			return true;
		}
		return false;
	}
	
	
	void rot(float ang) {
		PMatrix3D rotmat = new PMatrix3D();
		rotmat.rotate(-ang, up.x, up.y, up.z);
		dir = rotmat.mult(dir, null);
	}
	
	void turn(float ang) {
		if (steps >= 0) steps++;
		animation = new Turn(ang);
	}
	float zing = 0;
	void draw(PGraphics pa, PImage tex) {
		pa.pushMatrix();
		pa.translate(pos.x, pos.y, pos.z);
		PVector x = up.cross(dir);
		PMatrix3D r = new PMatrix3D(
			x.x, up.x, dir.x, 0,
			x.y, up.y, dir.y, 0,
			x.z, up.z, dir.z, 0,
			  0,    0,     0, 1);
		pa.applyMatrix(r);
		pa.applyMatrix(rotstate);
 		pa.textureMode(PApplet.IMAGE);
//  		texturedSphere(0.5, texmap);
		pa.textureMode(PApplet.NORMALIZED);
		
		TexCube t = new TexCube();
		zing += 0.1;
		glsl.startShader();
		glsl.uniform3f(glsl.getUniformLocation("lol"), zing, 0, 0);
		t.draw(pa, tex, 0.5f);
		glsl.endShader();

 		//tcube.draw(0.5);
//  		pa.box(1);
		pa.popMatrix();
	}
}

class GLSL
{
  int programObject;
  GL gl;
  boolean vertexShaderEnabled;
  boolean vertexShaderSupported; 
  int vs;
  int fs;
  PApplet pa;
  
  GLSL(PApplet pa)
  {
	this.pa=pa;
    gl=((PGraphicsOpenGL)pa.g).gl;
    String extensions = gl.glGetString(GL.GL_EXTENSIONS);
    vertexShaderSupported = extensions.indexOf("GL_ARB_vertex_shader") != -1;
    vertexShaderEnabled = true;    
    programObject = gl.glCreateProgramObjectARB(); 
    vs=-1;
    fs=-1;
  }
  
  void loadVertexShader(String file)
  {
    String shaderSource=PApplet.join(pa.loadStrings(file),"\n");
    vs = gl.glCreateShaderObjectARB(GL.GL_VERTEX_SHADER_ARB);
    gl.glShaderSourceARB(vs, 1, new String[]{shaderSource},(int[]) null, 0);
    gl.glCompileShaderARB(vs);
    checkLogInfo(gl, vs);
    gl.glAttachObjectARB(programObject, vs); 
  }

  void loadFragmentShader(String file)
  {
    String shaderSource=PApplet.join(pa.loadStrings(file),"\n");
    fs = gl.glCreateShaderObjectARB(GL.GL_FRAGMENT_SHADER_ARB);
    gl.glShaderSourceARB(fs, 1, new String[]{shaderSource},(int[]) null, 0);
    gl.glCompileShaderARB(fs);
    checkLogInfo(gl, fs);
    gl.glAttachObjectARB(programObject, fs); 
  }

  int getAttribLocation(String name)
  {
    return(gl.glGetAttribLocationARB(programObject,name));
  }
  
  int getUniformLocation(String name)
  {
    return(gl.glGetUniformLocationARB(programObject,name));
  }
    
  void useShaders()
  {
    gl.glLinkProgramARB(programObject);
    gl.glValidateProgramARB(programObject);
    checkLogInfo(gl, programObject);
  }
  
  void startShader()
  {
    gl.glUseProgramObjectARB(programObject); 
  }
  
  void endShader()
  {
    gl.glUseProgramObjectARB(0); 
  }
  
  void checkLogInfo(GL gl, int obj)  
  {
    IntBuffer iVal = BufferUtil.newIntBuffer(1);
    gl.glGetObjectParameterivARB(obj, GL.GL_OBJECT_INFO_LOG_LENGTH_ARB, iVal);
 
    int length = iVal.get();
    if (length <= 1)  
    {
	return;
    }
    ByteBuffer infoLog = BufferUtil.newByteBuffer(length);
    iVal.flip();
    gl.glGetInfoLogARB(obj, length, iVal, infoLog);
    byte[] infoBytes = new byte[length];
    infoLog.get(infoBytes);
    pa.println("GLSL Validation >> " + new String(infoBytes));
  } 
  void uniform3f(int location, float v0, float v1, float v2)
{
  gl.glUniform3fARB(location, v0, v1, v2);
}

}
