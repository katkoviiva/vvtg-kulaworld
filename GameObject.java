import java.util.*;
import saito.objloader.*;
import processing.core.*;
import processing.opengl.*;

class GameObject {
	OBJModel model;
	PVector pos;
	PApplet pa;
	PVector up;
	PMatrix3D mat;
	GameObject(PApplet pap, OBJModel mdl, PVector p, PVector u) {
		pa = pap;
		model = mdl;
		pos = p;
		up = u;
		mat = new PMatrix3D();
	}
	// alussa kolikon pinnan normaali y-akselia päin
	// -> jos up menee y:hyn niin käännä vaikka x:n suhteen 90°
	// TODO: mieti mihin kolikon yläreuna osoittaa ja asettele niin ettei ole ylösalaisin maassa
	void draw() {
		pa.pushMatrix();
		pa.translate(pos.x, pos.y, pos.z);
		mat.reset();
		mat.rotate(pa.millis()*0.00314159f, up.x, up.y, up.z);
		pa.applyMatrix(mat);
		if (up.y != 0) pa.rotateX((float)Math.PI/2f);
// 		pa.rotateX(pa.millis()/1000.0f);
// 		pa.rotateY(pa.millis()/2000.0f);
// 		pa.rotateZ(pa.millis()/3000.0f);
		model.draw();
		pa.popMatrix();
	}
}
