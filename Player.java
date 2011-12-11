import processing.core.*;
import java.util.*;
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
	void render(PGraphics pa) {
		zing += 0.1;
		glsl.startShader();
		glsl.uniform3f(glsl.getUniformLocation("lol"), zing, 0, 0);
		mdl.draw();
		glsl.endShader();
	}
}
