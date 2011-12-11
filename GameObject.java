import processing.core.*;
import processing.opengl.*;
import saito.objloader.*;

// geneerinen objekti joka osaa liikkua pelikentällä animoiden itseään
// olennaisinta on paikka, ylösvektori ja suuntavektori
// esim. yli laidan mentäessä objekti kääntyy 90 astetta edessään olevalle pinnalle
public class GameObject {
	PVector pos, dir, up; // maailmakoordinaatistossa
	PMatrix3D rotstate = new PMatrix3D();
	World world;
	static final float normalspeed = 4.0f, fastspeed = 8.0f;
	float speed = normalspeed;
	int steps;
	OBJModel mdl;
	PApplet pa;
	
	// joku animaatio kahden tilanteen välillä, varastoi alkutilan ja pyörittää objektia jotenkin ajan kuluessa
	abstract class Animation {
		PVector opos, odir, oup;
		PMatrix3D orotstate;
		float time;
		Animation() { start(); }
		abstract void animate(float time);
		void start() {
			// oliks näille mitään fiksua tapaa syväkopioida? ei oo copyconstructoria ainakaan.
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

	// eteenpäin kävely liikuttaa ja pyörittää peliobjektia
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
	// pudotessa reunan yli mennään siellä olevalle pinnalle pyörittämällä ylösvektoria
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
	// edellistä muistuttava tapaus jossa kiivetään edessä olevan pystyseinän pinnalle
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
		}
	}
	
	// rintamasuunta kääntyy vasemmalle/oikealle
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
	GameObject(PVector p, PVector d, PVector u, World w, PApplet pap, OBJModel model) {
		pos = p;
		dir = d;
		up = u;
		world = w;
		pa = pap;
		mdl = model;
	}

	void update(float dt) {
		if (animation != null) {
			if (!animation.run(dt)) {
				animation = null;
			}
		}
	}
	// kävellään normaalisti
	// where: 1=eteenpäin, -1=taaksepäin
	void walk(int where) {
		if (steps >= 0) steps++;
		PVector dest = PVector.add(pos, PVector.mult(dir, where));
		if (hitCheck(dest, where, true)) return;
		if (dropCheck(dest, where, true)) return;
		animation = new Walk(where);
	}
	// edessä alla ei mitään? kaadutaanpas
	boolean dropCheck(PVector p, int where, boolean anim) {
		if (!world.hasBlk(PVector.add(p, PVector.mult(up, -1)))) {
			if (anim) animation = new FallRotation(where);
			return true;
		}
		return false;
	}
	// edessä odottaa seinä? noustaan ylöspäin
	boolean hitCheck(PVector p, int where, boolean anim) {
		if (world.hasBlk(p)) {
			if (anim) animation = new HitRotation(where);
			return true;
		}
		return false;
	}
	// katselukääntely
	void rot(float ang) {
		PMatrix3D rotmat = new PMatrix3D();
		rotmat.rotate(-ang, up.x, up.y, up.z);
		dir = rotmat.mult(dir, null);
	}
	// kääntymisanimaatio alkaa näin
	void turn(float ang) {
		if (steps >= 0) steps++;
		animation = new Turn(ang);
	}
	
	// kalikan transformaatio kivaan paikkaan ja mukavaan koordinaatistoon
	void draw(PGraphics pa) {
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
		pa.textureMode(PApplet.NORMALIZED);
		render(pa);
		pa.popMatrix();
	}
	
	// itse piirto tapahtuu tässä, helpompi ylikuormittaa
	void render(PGraphics pa) {
		mdl.draw();
	}
}
