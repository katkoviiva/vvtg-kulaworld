import java.util.*;
import saito.objloader.*;
import processing.core.*;
import processing.opengl.*;

class GameObject {
	OBJModel model;
	PVector pos;
	PApplet pa;
	GameObject(PApplet pap, OBJModel mdl, PVector p) {
		pa = pap;
		model = mdl;
		pos = p;
	}
	void draw() {
		pa.pushMatrix();
		pa.translate(pos.x, pos.y, pos.z);
		pa.rotateX(pa.millis()/1000.0f);
		pa.rotateY(pa.millis()/2000.0f);
		pa.rotateZ(pa.millis()/3000.0f);
		model.draw();
		pa.popMatrix();
	}
}
