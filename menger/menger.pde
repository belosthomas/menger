/*****

TODO : 
 1. Faire plein de boutons (virer les trucs qui servent pas, et renorm du gradient)
 2. Gérer les zig-zag
 3. Ecrire le flow unitaire, créer une fonction menger puissance n (à vérifier)
 4. Chirurgie
 5. UN CODE TOUT JOLIE !

*****/

Curve C = new Curve();
float vertexSize = 10;    // for drawing vertices as disks
int backgroundColor = 255;
boolean make_curve = true;

public static final int FLOW_MENGER_HOMOTHETIC_SIMPLE = 0;
public static final int FLOW_MENGER_RENORMALIZED_SIMPLE = 1;
public static final int FLOW_MENGER_HOMOTHETIC_UNIT = 2;
public static final int FLOW_MENGER_HOMOTHETIC_POWER = 3;

boolean flow = false;
int mode = FLOW_MENGER_HOMOTHETIC_SIMPLE;
float power = 1;

float tau = 10;       // basic time interval

int informationYOffset = 10;

void setup() {
  frameRate(25);
  size(500, 500);
  background(backgroundColor);
  fill(50); // text color
  // C = regularngon(5, 0, 0, 100);
}

void draw() {
  
  if (flow && mode == FLOW_MENGER_HOMOTHETIC_SIMPLE) {
    float oldArea = C.area();
    PVector oldCentroid = C.centroid();
    C.vertices = C.getMengerFlows(tau);
    float newArea = C.area();
    
    float lambda = sqrt(oldArea / newArea);
    C.vertices = C.getHomothetic(lambda);
  
    PVector newCentroid =  C.centroid();
    C.vertices = C.getTranslation(oldCentroid.sub(newCentroid));
  
  }
  
  if (flow && mode == FLOW_MENGER_RENORMALIZED_SIMPLE) {
    PVector oldCentroid = C.centroid();
    C.vertices = C.getRenormalizedMengerFlows(tau);
    
    PVector newCentroid =  C.centroid();
    C.vertices = C.getTranslation(oldCentroid.sub(newCentroid));
  }
  
  if (flow && mode == FLOW_MENGER_HOMOTHETIC_UNIT) {
    float oldArea = C.area();
    PVector oldCentroid = C.centroid();
    C.vertices = C.getUnitMengerFlows(tau);
    float newArea = C.area();
    
    float lambda = sqrt(oldArea / newArea);
    C.vertices = C.getHomothetic(lambda);
  
    PVector newCentroid =  C.centroid();
    C.vertices = C.getTranslation(oldCentroid.sub(newCentroid));
  
  }
  
  if (flow && mode == FLOW_MENGER_HOMOTHETIC_POWER) {
    float oldArea = C.area();
    PVector oldCentroid = C.centroid();
    C.vertices = C.getPowerMengerFlows(tau, power);
    float newArea = C.area();
    
    float lambda = sqrt(oldArea / newArea);
    C.vertices = C.getHomothetic(lambda);
  
    PVector newCentroid =  C.centroid();
    C.vertices = C.getTranslation(oldCentroid.sub(newCentroid));
  
  }
  
  
  background(backgroundColor);              // erases for new images
  translate(width/2, height/2);  // coordinate offset to center the originf
  C.drawCurve();
  
  informationYOffset = 10;
  
  drawInformationText("turning number : "+C.turningNumber());
  drawInformationText("area : "+C.area());
  drawInformationText("tau = " + tau + "(use 'u' and 'i' key to change)");
  drawInformationText("mode = " + modeToText(mode) + "(use 'm' key to change)");
  drawInformationText("power = " + power  + "(use 'e' and 'r' key to change)");
  
  C.drawMengerEdge();
  C.drawCentroid();
  
}

void drawInformationText(String str) {
  text(str, -width/2+10, height/2-informationYOffset);
  informationYOffset += 20;
}

String modeToText(int m) {
  if (m == 0) return "Homothetic Simple";
  if (m == 1) return "Renormalized Simple";
  if (m == 2) return "Homothetic Unit";
  if (m == 3) return "Homothetic Power";
  return "Unkwnown";
}

void mouseClicked() {
  PVector point = new PVector();
  if (make_curve) {
    point.set(mouseX - width / 2, mouseY - height / 2); // coordinate offset to center the origin
    C.addVertex(point);
  }
}  

void keyReleased() {
  if (key == 'c') {
    //println("curve started");
    if (make_curve && C.vertices.size() >= 3) {  // we close the loop
      C.closed = true;
    } else {  // we start a new loop
      background(100);
      C.vertices.clear();
      C.closed = false;
    }
    make_curve = !make_curve;
  }
  if (key == 's') {
    saveFrame();
  }
 
  if (key == 'f') {
    flow = !flow;
  }
  
  if (key == 'm') {
    mode = (mode + 1) % 4;
  }
  
  if (key == 'u') tau *= 2;
  
  if (key == 'i') tau *= 0.5;
  
  if (key == 'e') power *= 2;
  
  if (key == 'r') power *= 0.5;
  
}

////// CLASSES  ////////

class Curve {
  ArrayList<PVector> vertices = new ArrayList<PVector>();
  boolean closed;    // true if the curve is closed

  void addVertex(PVector p) {
    vertices.add(p);
  }

  void drawCurve() {
    int n = vertices.size();
    PVector current, next;
    stroke(0, 0, 0);
    // draw lines first
    for (int i=0; i < n-1; i++) {
      current = vertices.get(i);
      next = vertices.get(i+1);
      line(current.x, current.y, next.x, next.y);
    }
    if (closed) {
      current = vertices.get(n-1);
      next = vertices.get(0);
      line(current.x, current.y, next.x, next.y);
    }

    // now draw vertices
    for (int i=0; i < n; i++) {
      current = vertices.get(i);
      ellipse(current.x, current.y, vertexSize, vertexSize);
    }
  }
  
  int size() {
    return vertices.size();
  }

  float area() {
    int n = vertices.size();
    float a = 0;
    for (int i=0; i<n; i++) { 
      PVector e1 = C.vertices.get(i).copy();    // so that the i-th vertex is not modified
      a += -e1.cross(C.vertices.get((i+1)%n)).z; // vertical part of the cross product
      // minus sign because the screen in inverted in Processing
    }
    return(a/2);
  }
  
  int turningNumber() {
    int n = vertices.size();
    float totalAngle = 0;
    PVector v1,v2;
    for (int i=0; i<n; i++) {
      v1 = PVector.sub(vertices.get((i+n-1)%n),vertices.get(i));
      v2 = PVector.sub(vertices.get(i),vertices.get((i+1)%n));
      totalAngle += arcAngle(v1,v2);
    }
  return(-round(totalAngle/TWO_PI+0)); // inverted to compensate for screen symmetry
  }
  
  PVector getVector(int i) {
    PVector i1 = vertices.get((i + 1) % vertices.size());
    PVector i0 = vertices.get((i + 0) % vertices.size());
    return new PVector(i1.x - i0.x, i1.y - i0.y);
  }
  
  PVector getUnitVector(int i) {
    return vectorToUnit(getVector(i));
  }
  
  ArrayList<PVector> getUnitVectors() {
    ArrayList<PVector> vectors = new ArrayList<PVector>();
    for (int i = 0; i < vertices.size(); i++) {
      vectors.add(getUnitVector(i));
    }
    return vectors;
  }

  PVector centroid() {
    if (vertices.size() == 0) {
      return new PVector(0, 0);
    }
    float x = 0, y = 0;
    for (int i = 0; i < vertices.size(); i++) {
      x += vertices.get(i).x;
      y += vertices.get(i).y;
    }
    return new PVector(x / vertices.size(), y / vertices.size());
  }
  
  void drawCentroid() {
    stroke(0, 200, 0);
    PVector current = centroid();
    ellipse(current.x, current.y, vertexSize, vertexSize); 
  }
  
  ArrayList<PVector> getHomothetic(float r) {
    PVector c = centroid();
    
    ArrayList<PVector> vectors = new ArrayList<PVector>();
    for (int i = 0; i < vertices.size(); i++) {
      PVector v = vertices.get(i).copy();
      vectors.add(new PVector(r * (v.x - c.x) + c.x, r * (v.y - c.y) + c.y));
    }
    return vectors;
  }
  
  ArrayList<PVector> getTranslation(PVector t) {    
    ArrayList<PVector> vectors = new ArrayList<PVector>();
    for (int i = 0; i < vertices.size(); i++) {
      PVector v = vertices.get(i).copy().add(t);
      vectors.add(v);
    }
    return vectors;
  }
  
  
  PVector getMengerEdgeFlow(int i) {
    PVector v = vertices.get((i) % vertices.size());
    PVector p = vertices.get((i + 1) % vertices.size());
    
    PVector vm = vertices.get((i - 1 + vertices.size()) % vertices.size());
    PVector pm = vertices.get((i + 2) % vertices.size());
    
    PVector v2 = midAngle(v.copy(), p.copy(), vm.copy());
    PVector p2 = midAngle(p.copy(), v.copy(), pm.copy());
    
    PVector intersection = intersection(v.copy(), v2.copy(), p.copy(), p2.copy());
    if (intersection == null) return null;
    
    PVector d = v.copy().sub(p); // d est un vecteur directeur de l'arrête
    PVector n = new PVector(-d.y, d.x); // n est un vecteur normal à d
    n.div(n.mag());
    float r = abs(intersection.sub(v).dot(n));
    
    n.mult(1 / r);
    
    // On s'assure que le vecteur est orienté dans le bon sens
    if (n.dot(vm.copy().sub(v)) < 0) n.mult(-1);
    
    return n;
    
  }
  
  PVector getMengerFlow(int i, float t) {
    PVector edgeFlow1 = getMengerEdgeFlow(i);
    PVector edgeFlow2 = getMengerEdgeFlow((i - 1 + vertices.size()) % vertices.size());
    
    if (edgeFlow1 == null || edgeFlow2 == null) return vertices.get((i) % vertices.size()).copy();
    
    return edgeFlow1.add(edgeFlow2).div(2).mult(t);
  }
  
  ArrayList<PVector> getMengerFlows(float t) {
    ArrayList<PVector> vectors = new ArrayList<PVector>();
    for (int i = 0; i < vertices.size(); i++) {
      vectors.add(getMengerFlow(i, t).add(vertices.get(i)));
    }
    return vectors;
  }
  
  ArrayList<PVector> areaGradient() {  // n-vector gradient of the area, for open or closed curves
    ArrayList<PVector> gradA = new ArrayList<PVector>();
    int n = vertices.size();
    PVector e1 = new PVector();
    for (int i=0; i<n; i++) {
      if (!this.closed && (i==0 || i==n-1)) {
        if (i==0) e1 = vertices.get(1).copy();  // only the next position
        if (i==n-1) e1 = vertices.get(n-2).copy().mult(-1); // only the previous position, negative
      } else {
        e1 = vertices.get((i+1)%n).copy();
        e1.sub(vertices.get((i-1+n)%n));
      }
      e1.rotate(HALF_PI);
      e1.mult(-0.5);
      gradA.add(e1);
    }  
    return(gradA);
  }

  ArrayList<PVector> getRenormalizedMengerFlows(float tau) {  // renormalized mean curvature
    ArrayList<PVector> H = this.getMengerFlows(tau);
    ArrayList<PVector> gA = this.areaGradient();
    float lambda = - ndot(H, gA)/ndot(gA, gA);
    return(nsum(H, nmult(gA, lambda)));
  }
  
  ArrayList<PVector> getUnitMengerFlows(float tau) {
    ArrayList<PVector> vectors = new ArrayList<PVector>();
    for (int i = 0; i < vertices.size(); i++) {
      PVector flow = getMengerFlow(i, tau);
      flow.div(flow.mag()).add(vertices.get(i));
      vectors.add(flow);
    }
    return vectors;
  }
  
  ArrayList<PVector> getPowerMengerFlows(float tau, float power) {
    return npow(getMengerFlows(tau), power);
  }
  
  void drawMengerEdge() {
    for (int i = 0; i < vertices.size(); i++) {
      PVector v = vertices.get((i) % vertices.size());
      PVector p = vertices.get((i + 1) % vertices.size());
      
      p = p.copy().add(v).div(2);
      
      PVector h = getMengerEdgeFlow(i);
      
      if (h != null) {
        h.mult(1000);
        stroke(0, 200, 255);
        line(p.x, p.y, p.x + h.x, p.y + h.y);
      }
    }  
  }
  
}


//////// MENGER SUBROUTINES  ////////////

/**
 * Retourne un point tels que l'angle entre les segments [center;left] et [center;right] soit les mêmes, et que la distance entre ce point et le centre soit 1.
 *
 * @param center Le point de référence
 * @param left Le premier point
 * @param right Le deuxième point
 *
 * @return Le point au milieu de l'angle
 */
PVector midAngle(PVector center, PVector left, PVector right) {
  
  // Par acquis de conscience, on copie les 3 vecteurs
  center = center.copy();
  left = left.copy();
  right = right.copy();
  
  // On se place dans le cas ou le centre est égal à zero
  left.sub(center);
  right.sub(center);
  
  // On normalize left et right
  left.div(left.mag());
  right.div(right.mag());
  
  // Le point d'angle entre left et right et l'addition de ses deux points
  left.add(right);
    
  // On retourne ce point dans le cas ou le centre n'est plus égal à zéro
  return center.add(left);
  
}

/**
 * Retourne le PVector de l'intersection de deux droites passant respectivemetnt par a1 et a2, et b1 et b2.
 *
 * @param a1 Un premier point appartenant à la première droite
 * @param a2 Un deuxième point appartenant à la première droite
 * @param b1 Un premier point appartenant à la deuxième droite
 * @param b2 Un deuxième point appartenant à la deuxième droite
 *
 * @return Le PVector de l'intersection de deux droites
 */
PVector intersection(PVector a1, PVector a2, PVector b1, PVector b2) {
  
  a1.z = 1;
  a2.z = 1;
  b1.z = 1;
  b2.z = 1;
  
  // En coordonnée barycentrique, l'intersection est (a1 Λ a2) Λ (b1 Λ b2)
  PVector p = a1.cross(a2).cross(b1.cross(b2));
  
  // On vérifie par acquis de conscience que les droites ne sont pas parrallèles
  if (p.z == 0) return null;
  
  // On retourne le point obtenu
  p.div(p.z);
  return p;
}

//////// SUBROUTINES  ////////////

Curve regularngon(int n, float xo, float yo, float radius) {
  C = new Curve();
  C.closed = true;    // the curve is closed
  for (int i=0; i < n; i++) {
    PVector p = new PVector(xo + radius*cos(i*TWO_PI/n), yo + radius*sin(i*TWO_PI/n));
    C.addVertex(p);
  }
  return(C);
}

float arcAngle(PVector v1, PVector v2) {
  float r = atan2(v2.y, v2.x) - atan2(v1.y, v1.x);
  if (r<-PI) {
    r += 2*PI;
  }
  if (r>PI) {
    r -= 2*PI;
  }
  return(r);
}

float distance(PVector p1, PVector p2) {
  return sqrt(pow((p1.x - p2.x),2) + pow((p1.y - p2.y),2));
}

float distance(PVector p1) {
  return sqrt(pow(p1.x,2) + pow(p1.y,2));
}

PVector vectorToUnit(PVector v) {
  float d = distance(v);
  return new PVector(v.x / d, v.y / d);
}

float ndot(ArrayList<PVector> U, ArrayList<PVector> V) {  // scalar product between n-vectors
  float s = 0;
  for (int i=0; i<min(U.size(), V.size()); i++) {
    s += PVector.dot(U.get(i), V.get(i));
  }
  return(s);
}

ArrayList<PVector> nsum(ArrayList<PVector> U, ArrayList<PVector> V) {  // addition between 2 n-vectors
  ArrayList<PVector> W = new ArrayList<PVector>();
  for (int i=0; i<min(U.size(), V.size()); i++) {
    W.add(PVector.add(U.get(i), V.get(i)));
  }
  return(W);
}

ArrayList<PVector> nmult(ArrayList<PVector> U, float lambda) {  // multiplication of n-vector by a float
  ArrayList<PVector> W = new ArrayList<PVector>();
  for (int i=0; i<U.size(); i++) {
    W.add(PVector.mult(U.get(i), lambda));
  }
  return(W);
}

ArrayList<PVector> npow(ArrayList<PVector> U, float lambda) {  // multiplication of n-vector by a float
  ArrayList<PVector> W = new ArrayList<PVector>();
  for (int i=0; i<U.size(); i++) {
    W.add(new PVector(pow(U.get(i).x, lambda), pow(U.get(i).y, lambda), pow(U.get(i).z, lambda)));
  }
  return(W);
}

ArrayList<PVector> nnorm(ArrayList<PVector> U) {  // multiplication of n-vector by a float
  ArrayList<PVector> W = new ArrayList<PVector>();
  for (int i=0; i<U.size(); i++) {
    W.add(U.get(i).copy().div(U.get(i).mag()));
  }
  return(W);
}
