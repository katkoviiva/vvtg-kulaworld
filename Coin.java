import processing.core.*;
import saito.objloader.*;

class Coin extends GameObject {
	public Coin(PVector p, PVector d, PVector u, World w, PApplet pa, OBJModel model) {
		super(p, d, u, w, pa, model);
	}
	void update(float dt) {
		rot(dt);
	}
}

